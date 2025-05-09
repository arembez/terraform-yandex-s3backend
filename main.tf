# Creates a Yandex Object Storage bucket for storing Terraform state files
resource "yandex_storage_bucket" "state" {
  # Current project tag
  tags = { project = local.project_name }
  # Name of the storage bucket
  bucket = local.bucket_name
  # Grant all privileges to the system account
  grant {
    id          = yandex_iam_service_account.sa.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }
  # Enables server-side encryption using KMS
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key.id # KMS key ID for encryption
        sse_algorithm     = "aws:kms"                       # SSE algorithm
      }
    }
  }
  # Enables versioning for the bucket (important for state history)
  versioning {
    enabled = true
  }
  # Force destroy bucket when backend is destroying
  force_destroy = true
  # Automatically deletes non-current versions after 30 days
  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 30
    }
  }
  # Ensures required resources are created first
  depends_on = [null_resource.s3_prerequisites]
}
# Creates a YDB Serverless database in Yandex Cloud
# Yes, one project - one database
resource "yandex_ydb_database_serverless" "database" {
  description = "YDB Serverless database for Terraform state locking"
  # Current project tag
  labels = { project = local.project_name }
  # Database's name
  name = local.ydb_name
}
# Ensures IAM permissions and keys are in place before creating the S3 bucket
resource "null_resource" "s3_prerequisites" {
  triggers = {
    sa         = yandex_iam_service_account.sa.id
    static_key = yandex_iam_service_account_static_access_key.sa-static-key.id
  }
}
# Waits until the YDB database is ready before proceeding
resource "null_resource" "ydb_ready" {
  triggers = {
    endpoint   = yandex_ydb_database_serverless.database.document_api_endpoint
    sa         = yandex_iam_service_account.sa.id
    ydb_member = yandex_ydb_database_iam_binding.editor.member
    access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  }
}
# Creates a DynamoDB-compatible table (via YDB) for state locking
resource "aws_dynamodb_table" "lock_table" {
  name         = "state-lock-table" # Name of the lock table
  hash_key     = "LockID"           # Primary key for lock entries
  billing_mode = "PAY_PER_REQUEST"  # On-demand billing (no need to specify read/write capacity)
  attribute {
    name = "LockID" # Lock ID used to identify a state lock
    type = "S"      # String type
  }
  depends_on = [null_resource.ydb_ready] # Wait until YDB is ready
}
