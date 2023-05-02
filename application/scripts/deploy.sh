#!/bin/bash

set -x

################   DEPLOY MOMO-STORE   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin
helm repo update nexus
helm upgrade --install momo-store nexus/momo-store \
  --namespace momo-store --create-namespace \
  --set global.tag="${TAG}" \
  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081 \
  --atomic --wait

# --set global.tag="v1.0.5"

################   SHOW INGRESS CONTROLLER IP   #################

kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip'


