#!/bin/bash

################   CONNECT TO CLUSTER   ################

yc config set token ${YC_TOKEN}
yc config set cloud-id ${YC_CLOUD_ID}
yc config set folder-id ${YC_FOLDER_ID}
yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force
yc managed-kubernetes cluster list

################   DEPLOY INGRESS CONTROLLER   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install ingress-nginx nexus/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.metrics.enabled=true \
  --set controller.metrics.port=10254 \
  --set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
  --set-string controller.podAnnotations."prometheus\.io/port"="10254" \
  --wait --atomic

################   DEPLOY CERT MANAGER   ################

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true \
  --wait --atomic

################   DEPLOY CLUSTER ISSUER  ################

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

################   DEPLOY MONITORING   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install monitoring-tools nexus/monitoring-tools \
  --namespace monitoring --create-namespace \
  --atomic --wait

################   DEPLOY KUBE-STATE-METRICS   ################

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics\
  --namespace monitoring \
  --atomic --wait

################   DEPLOY GRAFANA LOKI   ################

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
helm upgrade --install loki grafana/loki --namespace monitoring \
  --set minio.enabled=true --set loki.auth_enabled=false \
  --set read.replicas=1 --set write.replicas=1 --set backend.replicas=1 \
  --atomic --wait
