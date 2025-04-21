# AWS provider setup (configured to use Yandex YDB via DynamoDB endpoint override)
provider "aws" {
  region                   = "eu-west-1"                               # Dummy region; not used because endpoint is overridden
  profile                  = "default"                                 # Profile name
  shared_credentials_files = ["${path.module}/.aws/credentials.empty"] # Dummy file with empty credentials
  shared_config_files      = ["${path.module}/.aws/config.empty"]      # Dummy file with emty account_id
  # Skipping validations and metadata checks as we're not using real AWS
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  # Use Yandex IAM keys
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  # Override endpoint to point to Yandex YDB (acts like DynamoDB)
  endpoints {
    dynamodb = yandex_ydb_database_serverless.database.document_api_endpoint
  }
}


