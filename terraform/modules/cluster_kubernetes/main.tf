terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

##############    Create Kubernetes Cluster    ##############

resource "yandex_kubernetes_cluster" "k8s-corpsehead" {
  name       = "k8s-corpsehead"
  network_id = yandex_vpc_network.mynet.id
  master {
    public_ip = var.k8s_public_ip
    version   = var.k8s_version
    zonal {
      zone      = yandex_vpc_subnet.mysubnet.zone
      subnet_id = yandex_vpc_subnet.mysubnet.id
    }
    security_group_ids = [
      yandex_vpc_security_group.k8s-public-services.id,
      yandex_vpc_security_group.k8s-master-whitelist.id
    ]
  }
  service_account_id      = yandex_iam_service_account.myaccount.id
  node_service_account_id = yandex_iam_service_account.myaccount.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-admin,
    yandex_resourcemanager_folder_iam_member.storage-editor,
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller
  ]
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
}

##############    Create VPC Network    ##############

resource "yandex_vpc_network" "mynet" {
  name = "mynet"
}

##############    Create VPC Subnet    ##############

resource "yandex_vpc_subnet" "mysubnet" {
  v4_cidr_blocks = ["10.1.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.mynet.id
}
