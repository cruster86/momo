#!/bin/bash

set -x

yc config set token ${YC_TOKEN} &&\
yc config set cloud-id b1gq442484mq45tns89c &&\
yc config set folder-id b1ggq6pgr3l3rc0t76s1

yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force

kubectl cluster-info && kubectl get nodes

helm repo add examples https://helm.github.io/examples

helm repo list

kubectl get ns test || kubectl create ns test

helm upgrade --install ahoy --namespace test examples/hello-world --debug --atomic --wait

# kubectl get ns momo-store || kubectl create ns momo-store

# echo "${NEXUS_REPO_PASS}" | helm repo add nexus https://nexus.k8s.praktikum-services.tech/repository/momo-store-vladislav-lesnik-helm/ --username ${NEXUS_REPO_USER} --password-stdin

# helm repo update nexus

#helm upgrade --install momo-store nexus/momo-store -n momo-store \
#  --set global.tag="${TAG}" \
#  --debug --atomic --wait \
#  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081

kubectl apply -f - <<END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
  namespace: hello
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello-app
        image: cr.yandex/crpjd37scfv653nl11i9/hello:1.1
---
apiVersion: v1
kind: Service
metadata:
  name: hello
  namespace: hello
spec:
  ports:
  # Порт сетевого балансировщика, на котором будут обслуживаться пользовательские запросы.
  - port: 80
    name: plaintext
    # Порт контейнера, на котором доступно приложение.
    targetPort: 8080
  # Метки селектора, использованные в шаблоне подов при создании объекта Deployment.
  selector:
    app: hello
  type: LoadBalancer
END
