##############    Kubernetes Cluster Settings    ##############

variable "k8s_public_ip" {
  default = true
}

variable "k8s_version" {
  type    = string
  default = "1.22"
}

variable "network_id" {
  type    = string
}

variable "zone" {
  type    = string
}

variable "subnet_id" {
  type    = string
}

variable "security_group_ids" {
  type    = string
}

variable "key_id" {
  type    = string
}

variable "service_account_id" {
  type    = string
}

variable "depends" {
  type    = string
}

















