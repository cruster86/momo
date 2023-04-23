#!/bin/sh

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
key        = "momo-store.terraform.tfstate"
access_key = "${S3_KEY_ID}"
secret_key = "${S3_SECRET}"
skip_region_validation      = true
skip_credentials_validation = true
EOF
