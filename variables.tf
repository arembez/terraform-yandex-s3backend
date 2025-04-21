# Define common local values derived from the project name
locals {
  # Normalize project name:
  # - fallback to current directory name if var.project_name is empty
  # - remove invalid characters
  # - convert to lowercase
  # - limit to 63 characters (for resource naming compatibility)
  project_name = substr(lower(replace(coalesce(var.project_name, basename(abspath(path.root))), "/[^a-zA-Z0-9-]|-+$/", "-")), 0, 63)

  bucket_name  = "${local.project_name}-backend"     # S3 bucket name for storing Terraform backend state
  ydb_name     = "${local.project_name}-backend"     # YDB database name (used for DynamoDB-compatible lock table)
  sa_name      = "${local.project_name}-backend-sa"  # Name for the main service account
  kms_name     = "${local.project_name}-backend-kms" # KMS key name for server-side encryption
  sa-cicd_name = "${local.project_name}-cicd-sa"     # Service account name for CI/CD usage
}

# Optional project name to customize resource naming
variable "project_name" {
  type        = string
  description = "Optional custom name for the project. If left blank, the project directory name will be used."
  default = ""
}
