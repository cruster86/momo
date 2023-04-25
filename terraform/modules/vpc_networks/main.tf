terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
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
