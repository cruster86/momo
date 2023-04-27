#!/bin/sh

set -x

## Create CLI configuration file

cat << EOF > ~/.terraformrc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF

## Create meta file

cat << EOF > meta.txt 
#cloud-config
users:
  - default
  - name: ubuntu
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: true
    home: /home/ubuntu
    ssh_authorized_keys:
      - ${SSH_PUB_KEY}
EOF

## Create backend.conf

cat << EOF > backend.conf
endpoint   = "storage.yandexcloud.net"
bucket     = "momo-store-tfstate"
region     = "ru-central1"
key        = "momo-store-k8s.terraform.tfstate"
access_key = "${S3_KEY_ID}"
secret_key = "${S3_SECRET}"
skip_region_validation      = true
skip_credentials_validation = true
EOF

## Create variables.tf

cat << EOF > variables.tf
##############    Provider Settings    ##############

variable "token" {
  type    = string
  default = "${YC_TOKEN}"
}

variable "cloud_id" {
  type    = string
  default = "${YC_CLOUD_ID}"
}

variable "folder_id" {
  type    = string
  default = "${YC_FOLDER_ID}"
}

##############    IAM Service Account Settings    ##############

variable "sa_name" {
  type    = string
  default = "k8s-admin"
}

##############    KMS Key Settings    ##############

variable "kms_name" {
  type    = string
  default = "kms-key"
}

variable "kms_algorithm" {
  type    = string
  default = "AES_128"
}

variable "kms_period" {
  description =  "1 year"
  type    = string
  default = "8760h"
}

##############    Kubernetes Cluster Settings    ##############

variable "k8s_public_ip" {
  default = true
}

variable "k8s_version" {
  type    = string
  default = "1.22"
}
EOF
