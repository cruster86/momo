#!/bin/bash

set -x

################   CONNECT TO CLUSTER   ################

yc config set token ${YC_TOKEN}
yc config set cloud-id ${YC_CLOUD_ID}
yc config set folder-id ${YC_FOLDER_ID}
yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force
yc managed-kubernetes cluster list

################   DEPLOY HELM INGRESS CONTROLLER   ################

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --wait --atomic

################   DEPLOY KUBE CETRT-MANAGER   ################

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true \
  --wait --atomic

################   DEPLOY KUBE CLUSTER ISSUER  ################

#kubectl apply -f - <<END
#apiVersion: cert-manager.io/v1
#kind: ClusterIssuer
#metadata:
#  name: letsencrypt
#  namespace: default
#spec:
#  acme:
#    server: https://acme-v02.api.letsencrypt.org/directory
#    email: corpsehead@yandex.ru
#    privateKeySecretRef:
#      name: letsencrypt-key
#    solvers:
#    - http01:
#        ingress:
#          class: nginx
#END

####################   SET RESOLVE ACME DNS01   ####################

# https://cloud.yandex.ru/docs/tutorials/infrastructure-management/cert-manager-webhook

git clone https://github.com/yandex-cloud/cert-manager-webhook-yandex.git
helm upgrade --install -n cert-manager yandex-webhook cert-manager-webhook-yandex/deploy/cert-manager-webhook-yandex/
SA_ID=$(yc iam service-account list | grep k8s-admin | awk '{print $2}')
yc iam key create iamkey --service-account-id=${SA_ID} --format=json --output=iamkey.json
kubectl create secret generic cert-manager-secret --from-file=iamkey.json -n cert-manager

kubectl apply -f - <<END
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: clusterissuer
 namespace: default
spec:
 acme:
  email: corpsehead@yandex.ru
  server: https://acme-staging-v02.api.letsencrypt.org/directory
  privateKeySecretRef:
    name: letsencrypt-key
  solvers:
  - dns01:
      webhook:
        config:
          folder: ${YC_FOLDER_ID}
          serviceAccountSecretRef:
            name: cert-manager-secret
            key: iamkey.json
        groupName: acme.cloud.yandex.com
        solverName: yandex-cloud-dns
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: momo-store
  namespace: default
spec:
  secretName: momo-tls
  issuerRef:
    name: clusterissuer
    kind: ClusterIssuer
  dnsNames:
  - momo-store.corpsehead.space
END

################   DEPLOY HELM MOMO-STORE   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install momo-store nexus/momo-store \
  --namespace momo-store --create-namespace \
  --set global.tag="v1.0.5" \
  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081 \
  --atomic --wait

################   ADD RESOURCE RECORD   ################

IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip')
yc dns zone add-records --name my-public-zone --record "momo-store 600 A ${IP}"
