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
  network_id = var.network_id
  master {
    public_ip = var.k8s_public_ip
    version   = var.k8s_version
    zonal {
      zone      = var.zone
      subnet_id = var.subnet_id
    }
    security_group_ids = var.security_group_ids
  }
  service_account_id      = var.service_account_id 
  node_service_account_id = var.service_account_id
  depends_on = [var.depends]
  kms_provider {
    key_id = var.key_id
  }
}
