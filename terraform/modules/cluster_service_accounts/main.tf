##############    Create KMS Key    ##############

resource "yandex_kms_symmetric_key" "kms-key" {
  # A key for encrypting critical information, including passwords, OAuth tokens, and SSH keys.
  name              = var.kms_name
  default_algorithm = var.kms_algorithm
  rotation_period   = var.kms_period
}

##############    Create IAM Service Account    ##############

resource "yandex_iam_service_account" "myaccount" {
  name        = var.sa_name
  description = "K8S service account"
}

##############    Create Service Account Roles    ##############

resource "yandex_resourcemanager_folder_iam_member" "k8s-admin" {
  # The service account is assigned the k8s.clusters.admin role.
  folder_id = var.folder_id
  role      = "k8s.admin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-editor" {
  # The service account is assigned the storage.editor role.
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  # The service account is assigned the k8s.clusters.agent role.
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  # The service account is assigned the vpc.publicAdmin role.
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  # The service account is assigned the container-registry.images.puller role.
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.myaccount.id}"
}
