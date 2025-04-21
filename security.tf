# Gets the current Yandex Cloud client config (e.g., folder_id, cloud_id)
data "yandex_client_config" "client" {}

# Creates a primary service account for managing resources like S3, KMS, YDB
resource "yandex_iam_service_account" "sa" {
  description = "${local.project_name} service account for managing backend resources"
  name        = local.sa_name # Name defined in variables.tf
}

# Grants the service account admin access to Object Storage
resource "yandex_resourcemanager_folder_iam_member" "sa-admin-s3" {
  folder_id = data.yandex_client_config.client.folder_id
  role      = "storage.admin" # Full admin rights for Object Storage
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Grants the service account editor access to KMS for key management
resource "yandex_resourcemanager_folder_iam_member" "sa-editor-kms" {
  folder_id = data.yandex_client_config.client.folder_id
  role      = "kms.editor" # Permission to manage KMS keys
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Grants the service account editor access to YDB for managing databases
resource "yandex_resourcemanager_folder_iam_member" "sa-editor-ydb" {
  folder_id = data.yandex_client_config.client.folder_id
  role      = "ydb.editor" # Allows managing YDB Serverless
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Generates a static access key for the service account (used for S3-compatible APIs)
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  description        = "Used for S3-compatible APIs"
  service_account_id = yandex_iam_service_account.sa.id
}

# Creates a symmetric KMS key with a rotation period of 1 year
resource "yandex_kms_symmetric_key" "key" {
  description     = "Symmetric key for Object storage server-side encryption"
  labels          = { project = local.project_name }
  name            = local.kms_name
  rotation_period = "8760h" # Key rotation every 8760 hours (1 year)
}

# -----------------------------------
# CI/CD Setup
# -----------------------------------

# Creates a separate service account for CI/CD pipelines
resource "yandex_iam_service_account" "sa-cicd" {
  description = "${local.project_name} service account for CI/CD runners"
  name        = local.sa-cicd_name
}

# Grants full admin rights to the CI/CD service account
resource "yandex_resourcemanager_folder_iam_member" "sa-cicd-admin" {
  folder_id = data.yandex_client_config.client.folder_id
  role      = "admin" # Full access to all folder resources
  member    = "serviceAccount:${yandex_iam_service_account.sa-cicd.id}"
}

# Generates an RSA key for the CI/CD service account (used for programmatic auth)
resource "yandex_iam_service_account_key" "sa-cicd-auth-key" {
  description        = "Used for runners access"
  service_account_id = yandex_iam_service_account.sa-cicd.id
  key_algorithm      = "RSA_2048" # Strong asymmetric encryption key
}
