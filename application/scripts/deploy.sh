#!/bin/bash

################   CONNECT TO CLUSTER   ################

yc config set token ${YC_TOKEN}
yc config set cloud-id ${YC_CLOUD_ID}
yc config set folder-id ${YC_FOLDER_ID}
yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force
yc managed-kubernetes cluster list

################   DEPLOY MOMO-STORE   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install momo-store nexus/momo-store \
  --namespace momo-store --create-namespace \
  --set global.tag="${TAG}" \
  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081 \
  --atomic --wait

################   SHOW INGRESS CONTROLLER IP   #################

kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip'


