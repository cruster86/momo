################   DEPLOY KUBE MOMO-STORE-BACK   ################

#kubectl get ns momo-store || kubectl create ns momo-store && kubectl apply -f - <<END
#kind: Secret
#apiVersion: v1
#metadata:
#  name: docker-registry
#  namespace: momo-store
#data:
#  .dockerconfigjson: #ewoJImF1dGhzIjogewoJCSJnaXRsYWIucHJha3Rpa3VtLXNlcnZpY2VzLnJ1OjUwNTAiOiB7CgkJCSJhdXRoIjogIlpYSmhhMmh0WlhSNmVXRnViM1k2TlZrNWN#ESnlSM05RUVcxSFVIST0iCgkJfQoJfQp9
#type: kubernetes.io/dockerconfigjson
#
#---
#apiVersion: apps/v1
#kind: Deployment
#metadata:
#  name: momo-store-backend
#  namespace: momo-store
#  labels:
#    app: momo-store-backend
#spec:
#  replicas: 1
#  revisionHistoryLimit: 5
#  strategy:
#    rollingUpdate:
#      maxSurge: 25%
#      maxUnavailable: 25%
#    type: RollingUpdate
#  selector:
#    matchLabels:
#      app: momo-store-backend
#  template:
#    metadata:
#      annotations:
#        prometheus.io/port: "8081"
#        prometheus.io/scrape: "true"
#      labels:
#        app: momo-store-backend
#    spec:
#      containers:
#        - name: momo-store-backend
#          image: gitlab.praktikum-services.ru:5050/zerodistance/momo-store/momo-store-backend:v1.0.1
#          imagePullPolicy: IfNotPresent
#          ports:
#            - name: backend
#              containerPort: 8081
#          livenessProbe:
#            null
#      imagePullSecrets:
#      - name: docker-registry
#
#---
#apiVersion: v1
#kind: Service
#metadata:
#  name: momo-store-backend
#  namespace: momo-store
#  labels:
#    app: momo-store-backend
#spec:
#  type: ClusterIP
#  ports:
#    - port: 8081
#      protocol: TCP
#      targetPort: 8081
#  selector:
#    app: momo-store-backend
#END
#
#################   DEPLOY KUBE MOMO-STORE-FRONT   ################
#
#kubectl get ns momo-store || kubectl create ns momo-store && kubectl apply -f - <<END
#apiVersion: v1
#kind: ConfigMap
#metadata:
#  name: nginx-conf
#  namespace: momo-store
#data:
#  default.conf: |
#    server {
#        listen       80;
#        
#        location / {
#            root   /usr/share/nginx/html;
#            index  index.html index.htm;
#            try_files $uri $uri/ /index.html;
#        }
#    
#        location ~ ^/(?:products|categories|orders|metrics|auth/whoami) {
#            proxy_pass http://momo-store-backend:8081;
#        }
#    
#        error_page   500 502 503 504  /50x.html;
#        location = /50x.html {
#            root   /usr/share/nginx/html;
#        }
#    }
#
#---
#apiVersion: apps/v1
#kind: Deployment
#metadata:
#  name: momo-store-frontend
#  namespace: momo-store
#  labels:
#    app: momo-store-frontend
#spec:
#  replicas: 1
#  revisionHistoryLimit: 5
#  strategy:
#    rollingUpdate:
#      maxSurge: 25%
#      maxUnavailable: 25%
#    type: RollingUpdate
#  selector:
#    matchLabels:
#      app: momo-store-frontend
#  template:
#    metadata:
#      labels:
#        app: momo-store-frontend
#    spec:
#      containers:
#        - name: momo-store-frontend
#          image: gitlab.praktikum-services.ru:5050/zerodistance/momo-store/momo-store-frontend:v1.0.1
#          imagePullPolicy: IfNotPresent
#          ports:
#            - name: frontend
#              containerPort: 80
#          volumeMounts:
#            - name: nginx-conf
#              mountPath: /etc/nginx/conf.d/default.conf
#              subPath: default.conf
#              readOnly: true
#      imagePullSecrets:
#      - name: docker-registry
#      volumes:
#        - name: nginx-conf
#          configMap:
#            name: nginx-conf
#            items:
#              - key: default.conf
#                path: default.conf
#
#---
#apiVersion: v1
#kind: Service
#metadata:
#  name: momo-store-frontend
#  namespace: momo-store
#  labels:
#    app: momo-store-frontend
#spec:
#  type: ClusterIP
#  ports:
#    - port: 80
#      protocol: TCP
#      targetPort: 80
#  selector:
#    app: momo-store-frontend
#
#---
#apiVersion: networking.k8s.io/v1
#kind: Ingress
#metadata:
#  name: momo-store-frontend
#  namespace: momo-store
#spec:
#  ingressClassName: "nginx"
#  tls:
#    - hosts:
#        - "momo-store.corpsehead.space"
#  rules:
#    - host: "momo-store.corpsehead.space"
#      http:
#        paths:
#        - path: /
#          pathType: Prefix
#          backend:
#            service:
#              name: momo-store-frontend
#              port:
#                number: 80
#END

################   ADD RESOURCE RECORD   ################

kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].ip'
yc dns zone add-records --name my-public-zone --record "momo-store 600 A ${IP}"

#########################################################

# --set global.tag="${TAG}"

#########################################################

{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Chart.Name }}
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt"
spec:
  ingressClassName: {{ .Values.ingress.className | quote }}
  tls:
    - hosts:
        - {{ .Values.ingress.fqdn | quote }}
      secretName: letsencrypt
  rules:
    - host: {{ .Values.ingress.fqdn | quote }}
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: {{ .Chart.Name }}
              port:
                number: {{ .Values.ingress.port }}
{{- end }}
