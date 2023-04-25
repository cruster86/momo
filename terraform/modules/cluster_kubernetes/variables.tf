##############    Kubernetes Cluster Settings    ##############

variable "k8s_public_ip" {
  default = true
}

variable "k8s_version" {
  type    = string
  default = "1.22"
}
