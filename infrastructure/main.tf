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

resource "yandex_resourcemanager_folder_iam_member" "dns-editor" {
  # The service account is assigned the dns.editor role.
  folder_id = var.folder_id
  role      = "dns.editor"
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

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {
  # Сервисному аккаунту назначается роль "load-balancer.admin"
  folder_id = var.folder_id
  role = "load-balancer.admin"
  member = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
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
#    security_group_ids = [
#      yandex_vpc_security_group.k8s-public-services.id,
#      yandex_vpc_security_group.k8s-master-whitelist.id
#    ]
  }
  service_account_id      = yandex_iam_service_account.myaccount.id
  node_service_account_id = yandex_iam_service_account.myaccount.id
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-admin,
    yandex_resourcemanager_folder_iam_member.dns-editor,
    yandex_resourcemanager_folder_iam_member.storage-editor,
    yandex_resourcemanager_folder_iam_member.load-balancer-admin,
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

#resource "yandex_dns_zone" "my-zone" {
#  name        = "my-public-zone"
#  description = "momo-store"
#
#  labels = {
#    label1 = "momo-store"
#  }
#
#  zone    = "corpsehead.space."
#  public  = true
#}

#resource "yandex_dns_recordset" "rs1" {
#  zone_id = yandex_dns_zone.my-zone.id
#  name    = "momo-store.corpsehead.space."
#  type    = "A"
#  ttl     = 300
#  data    = ["${yandex_kubernetes_cluster.k8s-corpsehead.master.0.external_v4_address}"]
#}

##############    Create Security Groups    ##############

#resource "yandex_vpc_security_group" "k8s-master-whitelist" {
#  name        = "k8s-master-whitelist"
#  description = "Group rules allow access to the Kubernetes API from the internet. Apply the rules to the cluster only."
#  network_id  = yandex_vpc_network.mynet.id
#
#  ingress {
#    protocol       = "TCP"
#    description    = "Rule allows connections to the Kubernetes API via port 6443 from a specified network."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    port           = 6443
#  }
#
#  ingress {
#    protocol       = "TCP"
#    description    = "Rule allows connections to the Kubernetes API via port 443 from a specified network."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    port           = 443
#  }
#}

#resource "yandex_vpc_security_group" "k8s-public-services" {
#  name        = "k8s-public-services"
#  description = "Group rules allow connections to services from the internet. Apply the rules only for node groups."
#  network_id  = yandex_vpc_network.mynet.id
#  ingress {
#    protocol          = "TCP"
#    description       = "Rule allows availability checks from load balancer's address range. It is required for the #operation of a fault-tolerant cluster and load balancer services."
#    predefined_target = "loadbalancer_healthchecks"
#    from_port         = 0
#    to_port           = 65535
#  }
#  ingress {
#    protocol          = "ANY"
#    description       = "Rule allows master-node and node-node communication inside a security group."
#    predefined_target = "self_security_group"
#    from_port         = 0
#    to_port           = 65535
#  }
#  ingress {
#    protocol       = "ICMP"
#    description    = "Rule allows debugging ICMP packets from internal subnets."
#    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
#  }
#  ingress {
#    protocol       = "TCP"
#    description    = "Rule allows incoming traffic from the internet to the NodePort port range. Add ports or change #existing ones to the required ports."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    from_port      = 30000
#    to_port        = 32767
#  }
#  egress {
#    protocol       = "ANY"
#    description    = "Rule allows all outgoing traffic. Nodes can connect to Yandex Container Registry, Yandex Object #Storage, Docker Hub, and so on."
#    v4_cidr_blocks = ["0.0.0.0/0"]
#    from_port      = 0
#    to_port        = 65535
#  }
#}

##############    Create Cluster Node Group    ##############

resource "yandex_kubernetes_node_group" "momo-group" {
  cluster_id  = yandex_kubernetes_cluster.k8s-corpsehead.id
  name        = "momo-group"
  description = "momo-group"
  version     = var.node_version

  labels = {
    "app" = "momo-store"
  }

  instance_template {
    platform_id = var.node_platform_id

    network_interface {
      nat        = var.node_nat
      subnet_ids = ["${yandex_vpc_subnet.mysubnet.id}"]
#      security_group_ids = [
#        yandex_vpc_security_group.k8s-public-services.id,
#        yandex_vpc_security_group.k8s-master-whitelist.id
#      ]
    }

    resources {
      memory        = var.node_memory
      cores         = var.node_cores
      core_fraction = var.core_fraction
    }

    boot_disk {
      type = var.node_disk_type
      size = var.node_disk_size
    }

    scheduling_policy {
      preemptible = var.node_scheduling
    }

    container_runtime {
      type = var.node_runtime
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_scale_policy
    }
  }

  allocation_policy {
    location {
      zone = var.node_location
    }
  }

  maintenance_policy {
    auto_upgrade = var.node_auto_upgrade
    auto_repair  = var.node_auto_repair
  }
}
