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

variable "kms_name" {
  type    = string
  default = "kms-key"
}

variable "kms_algorithm" {
  type    = string
  default = "AES_128"
}

variable "kms_period" {
  description =  "1 year"
  type    = string
  default = "8760h"
}
