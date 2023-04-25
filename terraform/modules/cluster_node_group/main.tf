##############    Create Cluster Node Group    ##############

resource "yandex_kubernetes_node_group" "momo-group" {
  cluster_id  = yandex_kubernetes_cluster.k8s-corpsehead.id
  name        = "momo-group"
  description = "momo-group"
  version     = "1.22"

  labels = {
    "app" = "momo-store"
  }

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.mysubnet.id}"]
      security_group_ids = [
        yandex_vpc_security_group.k8s-public-services.id,
        yandex_vpc_security_group.k8s-master-whitelist.id
      ]
    }

    resources {
      memory        = 2
      cores         = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  maintenance_policy {
    auto_upgrade = false
    auto_repair  = false
  }
}

