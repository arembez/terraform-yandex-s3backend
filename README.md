# terraform-yandex-s3backend

[![Releases](https://img.shields.io/github/v/release/arembez/terraform-yandex-s3backend)](https://github.com/arembez/terraform-yandex-s3backend/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A terraform module to enable [remote state management](https://developer.hashicorp.com/terraform/language/state/remote) with [S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3) for your terraform project. 
It creates an encrypted S3 bucket to store state files and a DynamoDB table for state locking and consistency checking.
Additionally, it generates all the necessary files in the project folder, including access keys for CI/CD pipelines.

## Features

- *Yandex Cloud Storage Bucket*: For storing Terraform state files with:
  - Server-side encryption using KMS
  - Versioning enabled
  - Automatic cleanup of old versions after 30 days
- *YDB Serverless database*: Acts as a DynamoDB-compatible lock table
- *Service accounts*: With appropriate permissions for both management and CI/CD

## Requirements

Before using this module you need:
- Terraform 1.0+
- Yandex Cloud account
- Yandex Cloud CLI configured with appropriate credentials

## Usage

1. Add the module block anywhere in your Terraform configuration.
   Optionally, set a project name. If you don’t, the folder name will be used instead.  

```hcl
module "s3backend" {
  source  = "arembez/terraform-yandex-s3backend"
  project_name = "some-project-name" #optional
}
```
2. Apply your terraform configuration
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
3. Reinitialize your configuration, answer 'yes'
```
$ terraform init
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| <a name="input_project_name"></a> [input\_project\_name](#input\_project\_name) | Optional custom name for the project. If left blank, the project directory name will be used. | `string` | no |

## Output files

| File name | Description |
|------|-------------|
| <a name="backend.tf"></a> [backend\.tf](#backend\.tf) | Backend configuration for your project |
| <a name=".aws/credentials"></a> [\.aws\/credentials](#\.aws\/credentials) | AWS credentials file for use with Terraform AWS provider pointing to YDB |
| <a name=".key.json"></a> [\.key\.json](#\.key\.json) | Service account key for CI/CD |
