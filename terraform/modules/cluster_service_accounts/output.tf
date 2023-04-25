output "kms-key" {
  value  = yandex_kms_symmetric_key.kms-key
}

output "myaccount" {
  value  = yandex_iam_service_account.myaccount
}

output "k8s-admin" {
  value  = yandex_resourcemanager_folder_iam_member.k8s-admin
}

output "storage-editor" {
  value  = yandex_resourcemanager_folder_iam_member.storage-editor
}

output "k8s-clusters-agent" {
  value  = yandex_resourcemanager_folder_iam_member.k8s-clusters-agent
}

output "vpc-public-admin" {
  value  = yandex_resourcemanager_folder_iam_member.vpc-public-admin
}

output "images-puller" {
  value  = yandex_resourcemanager_folder_iam_member.images-puller
}
