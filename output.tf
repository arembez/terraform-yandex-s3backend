# Ensures the .aws directory exists before writing credentials to it
resource "null_resource" "aws_dir" {
  # Create directory with secure permissions
  provisioner "local-exec" {
    when    = create
    command = "mkdir -m 700 -p ${path.root}/.aws"
  }
  # Remove directory on destroy (will fail if not empty)
  provisioner "local-exec" {
    when    = destroy
    command = "rm -d ${path.root}/.aws"
  }
}

# Writes AWS credentials file for use with Terraform AWS provider pointing to YDB
resource "local_sensitive_file" "aws_credentials" {
  filename        = "${path.root}/.aws/credentials"
  file_permission = "0600" # Secure file permissions
  content         = <<-EOT
    [${local.ydb_name}]
    aws_access_key_id = ${yandex_iam_service_account_static_access_key.sa-static-key.access_key}
    aws_secret_access_key = ${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}
  EOT
  # Clean up credentials file on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.root}/.aws/credentials"
  }
  depends_on = [null_resource.aws_dir] # Ensure directory is created first
}

# Renders and writes the backend.tf file using a template
resource "local_file" "backend_tf" {
  filename        = "${path.root}/backend.tf" # Save to the project root folder
  file_permission = "0644"                    # Readable by others if necessary (usually fine for backend config)
  # Populates template with values for S3 backend and DynamoDB-compatible locking
  content = templatefile("${path.module}/backend.tftpl", {
    profile           = local.bucket_name
    bucket_id         = local.bucket_name,
    key               = "terraform.tfstate",
    dynamodb_endpoint = yandex_ydb_database_serverless.database.document_api_endpoint,
    dynamodb_table    = aws_dynamodb_table.lock_table.id
  })
  # Clean up the backend config file on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.root}/backend.tf"
  }
}

# Securely writes the CI/CD service account key to a local JSON file
resource "local_sensitive_file" "cicd-key" {
  filename        = "${path.root}/.key.json" # Output path for the key file
  file_permission = "0600"                   # Only owner can read/write (very secure)
  content         = <<EOH
  {
    "id": "${yandex_iam_service_account_key.sa-cicd-auth-key.id}",
    "created_at": "${yandex_iam_service_account_key.sa-cicd-auth-key.created_at}",
    "key_algorithm": "${yandex_iam_service_account_key.sa-cicd-auth-key.key_algorithm}",
    "public_key": ${jsonencode(yandex_iam_service_account_key.sa-cicd-auth-key.public_key)},
    "private_key": ${jsonencode(yandex_iam_service_account_key.sa-cicd-auth-key.private_key)}
  }
  EOH

  # Clean up key file on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.root}/.key.json"
  }
}
