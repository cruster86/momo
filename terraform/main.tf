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
  depends_on = [module.vpc_networks]
  network_id  = module.vpc_networks.mynet.id
}


##############    Create Kubernetes Cluster    ##############

module "cluster_kubernetes" {
  source         = "./modules/cluster_kubernetes"
  depends_on = [
    module.cluster_security_groups,
    module.cluster_service_accounts
  ]
  service_account_id = module.cluster_service_accounts.myaccount.id
  network_id  = module.vpc_networks.mynet.id
  security_group_ids = [
    module.cluster_security_groups.k8s-public-services.id,
    module.cluster_security_groups.k8s-master-whitelist.id
  ]
  zone      = module.vpc_networks.mysubnet.zone
  subnet_id = module.vpc_networks.mysubnet.id
  key_id = module.cluster_service_accounts.kms-key.id
  depends = [
    module.cluster_service_accounts.k8s-admin,
    module.cluster_service_accounts.storage-editor,
    module.cluster_service_accounts.k8s-clusters-agent,
    module.cluster_service_accounts.vpc-public-admin,
    module.cluster_service_accounts.images-puller
  ]
}


##############    Create DNS Zone & Records    ##############

module "dns_zone_records" {
  source         = "./modules/dns_zone_records"
  depends_on = [module.cluster_kubernetes]
  data = [module.cluster_kubernetes.k8s-corpsehead.master.0.external_v4_address]
}


##############    Create Cluster Node Group    ##############

module "cluster_node_group" {
  source         = "./modules/cluster_node_group"
  depends_on = [
    module.cluster_kubernetes,
    module.vpc_networks,
    module.cluster_security_groups
  ]
  cluster_id = module.cluster_kubernetes.k8s-corpsehead.id
  subnet_ids = [module.vpc_networks.mysubnet.id] 
  security_group_ids = [
    module.cluster_security_groups.k8s-public-services.id,
    module.cluster_security_groups.k8s-master-whitelist.id
  ]
}
