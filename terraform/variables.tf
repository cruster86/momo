##############    Provider Settings    ##############

variable "token" {
  type    = string
  default = "y0_AgAAAAAFqC5fAATuwQAAAADhf8B_vNLCUvJETvyO1pRXrpo-yhLGQb0"
}

variable "cloud_id" {
  type    = string
  default = "b1gq442484mq45tns89c"
}

variable "folder_id" {
  type    = string
  default = "b1ggq6pgr3l3rc0t76s1"
}

##############    IAM Service Account Settings    ##############

variable "sa_name" {
  type    = string
  default = "k8s-admin"
}

##############    KMS Key Settings    ##############

#variable "kms_name" {
#  type    = string
#  default = "kms-key"
#}

#variable "kms_algorithm" {
#  type    = string
#  default = "AES_128"
#}

#variable "kms_period" {
#  type    = string
#  default = "8760h"
#}

##############    Kubernetes Cluster Settings    ##############

variable "k8s_public_ip" {
  default = true
}

variable "k8s_version" {
  type    = string
  default = "1.22"
}

##############    Kubernetes Node Group Settings    ##############

#variable "group_name" {
#  type    = string
#  default = "momo-group"
#}

#variable "group_version" {
#  type    = string
#  default = "1.22"
#}

#variable "group_label" {
#  type    = string
#  default = "momo-store"
#}

##############    Kubernetes Node Template Settings    ##############

#variable "node_platform" {
#  type    = string
#  default = "standard-v3"
#}

#variable "node_nat" {
#  default = true
#}

#variable "node_nem" {
#  default = "2"
#}

#variable "node_cpu" {
#  default = "2"
#}

#variable "node_fract" {
#  default = "20"
#}

#variable "node_disk_type" {
#  type    = string
#  default = "network-hdd"
#}

#variable "node_disk_size" {
#  default = "32"
#}

#variable "node_runtime" {
#  type    = string
#  default = "containerd"
#}

#variable "node_scale" {
#  default = "1"
#}

#variable "node_zone" {
#  type    = string
#  default = "ru-central1-a"
#}
