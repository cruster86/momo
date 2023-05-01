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
  --set controller.metrics.enabled=true
  --set-string controller.podAnnotations."prometheus\.io/scrape"="true"
  --set-string controller.podAnnotations."prometheus\.io/port"="10254"
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

kubectl apply -f - <<END
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: default
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: corpsehead@yandex.ru
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
    - http01:
        ingress:
          class: nginx
END

################   DEPLOY HELM MOMO-STORE   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install momo-store nexus/momo-store \
  --namespace momo-store --create-namespace \
  --set global.tag="v1.0.5" \
  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081 \
  --atomic --wait

################   SHOW INGRESS IP   #################

kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip'

################   DEPLOY HELM MONITORING   ################

helm upgrade --install monitoring-tools nexus/monitoring-tools \
  --namespace monitoring --create-namespace \
  --atomic --wait
