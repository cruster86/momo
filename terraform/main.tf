terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  backend "s3" {}
}


##############    Create VPC Networks    ##############

module "vpc_networks" {
  source         = "./modules/vpc_networks"
}


##############    Create IAM Service Accounts    ##############

module "cluster_service_accounts" {
  source         = "./modules/cluster_service_accounts"
}


##############    Create Security Groups    ##############

module "cluster_security_groups" {
  source         = "./modules/cluster_security_groups"
  depends_on = [module.vpc_networks.yandex_vpc_network.mynet.id]
#  network_id = module.vpc_networks.yandex_vpc_network.mynet.id
}


##############    Create Kubernetes Cluster    ##############

module "cluster_kubernetes" {
  source         = "./modules/cluster_kubernetes"
  depends_on = [
    module.cluster_security_groups,
    module.cluster_service_accounts
  ]
}


##############    Create DNS Zone & Records    ##############

module "dns_zone_records" {
  source         = "./modules/dns_zone_records"
  depends_on = [module.cluster_kubernetes]
}


##############    Create Cluster Node Group    ##############

module "cluster_node_group" {
  source         = "./modules/cluster_node_group"
  depends_on = [
    module.cluster_kubernetes,
    module.vpc_networks,
    module.cluster_security_groups
  ]
}
