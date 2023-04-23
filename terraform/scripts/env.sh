#!/bin/sh

apk update && apk add --no-cache nano curl wget unzip bash jq openssh-client

wget -q https://hashicorp-releases.yandexcloud.net/terraform/1.4.0/terraform_1.4.0_linux_amd64.zip &&\
  unzip terraform_1.4.0_linux_amd64.zip &&\
  mv terraform /usr/local/bin 

curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl &&\
  chmod +x ./kubectl &&\
  mv ./kubectl /usr/local/bin

curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash &&\
mv /root/yandex-cloud/bin/yc /usr/local/bin

wget -q https://get.helm.sh/helm-v3.11.0-linux-amd64.tar.gz &&\
  tar xzvf helm-v3.11.0-linux-amd64.tar.gz &&\
  chmod +x linux-amd64/helm &&\
  mv linux-amd64/helm /usr/local/bin
