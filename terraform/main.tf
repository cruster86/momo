terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  backend "s3" {}
}


##############    Create IAM Service Accounts    ##############

module "cluster_service_accounts" {
  source         = "./modules/cluster_service_accounts"
  depends_on = [module.cluster_kubernetes]
}


##############    Create Kubernetes Cluster    ##############

module "cluster_node_group" {
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


##############    Create Security Groups    ##############

module "cluster_security_groups" {
  source         = "./modules/cluster_security_groups"
  depends_on = [module.cluster_kubernetes]
}


##############    Create Cluster Node Group    ##############

module "cluster_node_group" {
  source         = "./modules/cluster_node_group"
  depends_on = [
    module.cluster_kubernetes,
    module.cluster_security_groups
  ]
}
