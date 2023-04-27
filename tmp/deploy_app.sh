#!/bin/bash

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
