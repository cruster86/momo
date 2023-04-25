terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  backend "s3" {}
}

##############    Create KMS Key    ##############

resource "yandex_kms_symmetric_key" "kms-key" {
  # A key for encrypting critical information, including passwords, OAuth tokens, and SSH keys.
  name              = var.kms_name
  default_algorithm = var.kms_algorithm
  rotation_period   = var.kms_period
}

##############    Create IAM Service Account    ##############

resource "yandex_iam_service_account" "myaccount" {
  name        = var.sa_name
  description = "K8S service account"
}

##############    Create Service Account Roles    ##############

resource "yandex_resourcemanager_folder_iam_member" "k8s-admin" {
  # The service account is assigned the k8s.clusters.admin role.
  folder_id = var.folder_id
  role      = "k8s.admin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-editor" {
  # The service account is assigned the storage.editor role.
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  # The service account is assigned the k8s.clusters.agent role.
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  # The service account is assigned the vpc.publicAdmin role.
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  # The service account is assigned the container-registry.images.puller role.
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
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

##############    Create DNS Zone & Records    ##############

resource "yandex_dns_zone" "my-zone" {
  name        = "my-public-zone"
  description = "momo-store"

  labels = {
    label1 = "momo-store"
  }

  zone    = "momo-store.corpsehead.space."
  public  = true
}

resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.my-zone.id
  name    = "momo-store.corpsehead.space."
  type    = "A"
  ttl     = 300
  data    = ["${yandex_kubernetes_cluster.k8s-corpsehead.master.0.external_v4_address}"]
}

##############    Create Security Groups    ##############

module "cluster_security_groups" {
  source         = "./terraform/modules/cluster_security_groups"
}

##############    Create Cluster Node Group    ##############

module "cluster_node_group" {
  source         = "./terraform/modules/cluster_node_group"
}
