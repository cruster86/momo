#!/bin/bash

set -x

################   CONNECT TO CLUSTER   ################

yc config set token ${YC_TOKEN}
yc config set cloud-id b1gq442484mq45tns89c
yc config set folder-id b1ggq6pgr3l3rc0t76s1

yc managed-kubernetes cluster get-credentials --id $(yc managed-kubernetes cluster list --format json | jq -r '.[].id') --external --force

yc managed-kubernetes cluster list

################   DEPLOY HELM AHOY   ################

#kubectl cluster-info && kubectl get nodes
#helm repo add examples https://helm.github.io/examples
#helm repo list
#kubectl get ns test || kubectl create ns test
#helm upgrade --install ahoy --namespace test examples/hello-world --debug --atomic --wait

################   DEPLOY HELM MOMO   ################

# kubectl get ns momo-store || kubectl create ns momo-store

# echo "${NEXUS_REPO_PASS}" | helm repo add nexus https://nexus.k8s.praktikum-services.tech/repository/momo-store-vladislav-lesnik-helm/ --username ${NEXUS_REPO_USER} --password-stdin

# helm repo update nexus

#helm upgrade --install momo-store nexus/momo-store -n momo-store \
#  --set global.tag="${TAG}" \
#  --debug --atomic --wait \
#  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081

################   DEPLOY HELM INGRESS CONTROLLER   ################

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx

################   DEPLOY KUBE CETRT-MANAGER   ################

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.yaml

################   DEPLOY KUBE ISSUER FOR NGINX-APP  ################

kubectl apply -f - <<END
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: corpsehead@yandex.ru
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
END

################   DEPLOY KUBE NGINX-APP   ################

kubectl get ns nginx || kubectl create ns nginx && kubectl apply -f - <<END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-nginx
  namespace: nginx
  labels:
    app: app-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-nginx
  template:
    metadata:
      labels:
        app: app-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: app-nginx
  namespace: nginx
  labels:
    app: app-nginx
spec:
  selector:
    app: app-nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-nginx-ingress
  namespace: nginx
  labels:
    app: app-nginx
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt"
spec:
  tls:
    - hosts:
      - momo-store.corpsehead.space
      secretName: letsencrypt
  rules:
    - host: momo-store.corpsehead.space
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: app-nginx
              port:
                number: 80
END

################   DEPLOY KUBE HELLO   ################

#kubectl get ns hello || kubectl create ns hello && kubectl apply -f - <<END
#apiVersion: apps/v1
#kind: Deployment
#metadata:
#  name: hello
#  namespace: hello
#spec:
#  replicas: 1
#  selector:
#    matchLabels:
#      app: hello
#  template:
#    metadata:
#      labels:
#        app: hello
#    spec:
#      containers:
#      - name: hello-app
#        image: cr.yandex/crpjd37scfv653nl11i9/hello:1.1
#---
#apiVersion: v1
#kind: Service
#metadata:
#  name: hello
#  namespace: hello
#spec:
#  ports:
#  # Порт сетевого балансировщика, на котором будут обслуживаться пользовательские запросы.
#  - port: 80
#    name: plaintext
#    # Порт контейнера, на котором доступно приложение.
#    targetPort: 8080
#  # Метки селектора, использованные в шаблоне подов при создании объекта Deployment.
#  selector:
#    app: hello
#  type: LoadBalancer
#END
