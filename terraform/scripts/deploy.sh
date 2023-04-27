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

################   DEPLOY KUBE MOMO-STORE-BACK   ################

kubectl get ns momo-store || kubectl create ns momo-store && kubectl apply -f - <<END
kind: Secret
apiVersion: v1
metadata:
  name: docker-registry
  namespace: momo-store
data:
  .dockerconfigjson: ewoJImF1dGhzIjogewoJCSJnaXRsYWIucHJha3Rpa3VtLXNlcnZpY2VzLnJ1OjUwNTAiOiB7CgkJCSJhdXRoIjogIlpYSmhhMmh0WlhSNmVXRnViM1k2TlZrNWNESnlSM05RUVcxSFVIST0iCgkJfQoJfQp9
type: kubernetes.io/dockerconfigjson

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: momo-store-backend
  namespace: momo-store
  labels:
    app: momo-store-backend
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  selector:
    matchLabels:
      app: momo-store-backend
  template:
    metadata:
      annotations:
        prometheus.io/port: "8081"
        prometheus.io/scrape: "true"
      labels:
        app: momo-store-backend
    spec:
      containers:
        - name: momo-store-backend
          image: gitlab.praktikum-services.ru:5050/zerodistance/momo-store/momo-store-backend:v1.0.1
          imagePullPolicy: IfNotPresent
          ports:
            - name: backend
              containerPort: 8081
          livenessProbe:
            null
      imagePullSecrets:
      - name: docker-registry

---
apiVersion: v1
kind: Service
metadata:
  name: momo-store-backend
  namespace: momo-store
  labels:
    app: momo-store-backend
spec:
  type: ClusterIP
  ports:
    - port: 8081
      protocol: TCP
      targetPort: 8081
  selector:
    app: momo-store-backend
END

################   DEPLOY KUBE MOMO-STORE-BACK   ################

kubectl get ns momo-store || kubectl create ns momo-store && kubectl apply -f - <<END
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: momo-store
data:
  default.conf: |
    server {
        listen       80;
        
        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
            try_files $uri $uri/ /index.html;
        }
    
        location ~ ^/(?:products|categories|orders|metrics|auth/whoami) {
            proxy_pass http://momo-store-backend:8081;
        }
    
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: momo-store-frontend
  namespace: momo-store
  labels:
    app: momo-store-frontend
spec:
  replicas: 1
  revisionHistoryLimit: 5
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  selector:
    matchLabels:
      app: momo-store-frontend
  template:
    metadata:
      labels:
        app: momo-store-frontend
    spec:
      containers:
        - name: momo-store-frontend
          image: gitlab.praktikum-services.ru:5050/zerodistance/momo-store/momo-store-frontend:v1.0.1
          imagePullPolicy: IfNotPresent
          ports:
            - name: frontend
              containerPort: 80
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
              readOnly: true
      imagePullSecrets:
      - name: docker-registry
      volumes:
        - name: nginx-conf
          configMap:
            name: nginx-conf
            items:
              - key: default.conf
                path: default.conf

---
apiVersion: v1
kind: Service
metadata:
  name: momo-store-frontend
  namespace: momo-store
  labels:
    app: momo-store-frontend
spec:
  type: ClusterIP
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: momo-store-frontend

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: momo-store-frontend
  namespace: momo-store
spec:
  ingressClassName: "nginx"
  tls:
    - hosts:
        - "momo-store.corpsehead.space"
  rules:
    - host: "momo-store.corpsehead.space"
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: momo-store-frontend
              port:
                number: 80
END

################   DEPLOY HELM MOMO-STORE   ################

echo ${NEXUS_REPO_PASS} | helm repo add nexus ${NEXUS_HELM_REPO} --username ${NEXUS_REPO_USER} --password-stdin

helm repo update nexus
#helm upgrade --install momo-store nexus/momo-store \
#  --namespace momo-store --create-namespace \
#  --set global.tag="${TAG}" \
#  --set global.backServiceName=momo-store-backend --set global.backServicePort=8081 \
#  --debug --atomic --wait

################   ADD RESOURCE RECORD   ################

kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip'

#yc dns zone add-records --name my-public-zone --record "momo-store 600 A ${IP}"
