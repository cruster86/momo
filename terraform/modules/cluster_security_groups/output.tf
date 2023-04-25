output "k8s-master-whitelist" {
  value  = yandex_vpc_security_group.k8s-master-whitelist
}

output "k8s-public-services" {
  value  = yandex_vpc_security_group.k8s-public-services
}
