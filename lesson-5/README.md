# Lesson 5 — Terraform: S3 backend, VPC, ECR

Terraform configuration that provisions:

1. A remote state backend on AWS — versioned **S3 bucket** for the state file and a **DynamoDB table** for state locking.
2. A **VPC** with three public and three private subnets across three availability zones, an Internet Gateway for the public tier, and a single NAT Gateway for the private tier.
3. An **ECR** repository for Docker images, with image scanning on push, an account-level access policy, and a lifecycle policy that retains the last 30 images.

## Project structure

```
lesson-5/
├── terraform.tf             # required_version + required_providers
├── providers.tf             # AWS provider config (region, default tags)
├── variables.tf             # Root-level input variables
├── main.tf                  # Wires the three modules together
├── backend.tf               # S3+DynamoDB remote state (commented for bootstrap)
├── outputs.tf               # Aggregated outputs from all modules
│
├── modules/
│   ├── s3-backend/          # State bucket + lock table
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                 # VPC, subnets, IGW, NAT, route tables
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── ecr/                 # ECR repository + lifecycle/access policy
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── README.md
```

## Modules

### `s3-backend`

Creates the storage layer used by Terraform itself for remote state.

| Resource | Purpose |
|---|---|
| `aws_s3_bucket.tfstate` | Holds `terraform.tfstate` for this and future projects. |
| `aws_s3_bucket_versioning` | Keeps every previous version of the state file (recoverable history). |
| `aws_s3_bucket_server_side_encryption_configuration` | AES-256 SSE so state is encrypted at rest. |
| `aws_s3_bucket_public_access_block` | Hard-block any accidental public ACL or policy. |
| `aws_dynamodb_table.tflock` | `LockID` hash-key table consumed by the S3 backend's locking protocol. PAY_PER_REQUEST (cheap when idle), with PITR and SSE on. |

Outputs: `bucket_name`, `bucket_arn`, `bucket_url`, `dynamodb_table_name`, `dynamodb_table_arn`.

### `vpc`

| Resource | Purpose |
|---|---|
| `aws_vpc.main` | `/16` VPC with DNS hostnames + DNS support enabled. |
| `aws_subnet.public[0..2]` | Three public subnets (one per AZ) with `map_public_ip_on_launch = true`. |
| `aws_subnet.private[0..2]` | Three private subnets (one per AZ). |
| `aws_internet_gateway.main` | Egress for the public tier. |
| `aws_eip.nat` + `aws_nat_gateway.main` | One NAT in the first public subnet so private workloads can reach the internet. |
| `aws_route_table.public` + associations | `0.0.0.0/0 → IGW` for all public subnets. |
| `aws_route_table.private` + associations | `0.0.0.0/0 → NAT` for all private subnets. |

Outputs: `vpc_id`, `vpc_cidr_block`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `nat_gateway_id`, `public_route_table_id`, `private_route_table_id`.

> **Note on cost.** A single NAT Gateway costs roughly $32/month + data transfer. To make the private tier highly available across AZ failures, change `aws_nat_gateway.main` and `aws_eip.nat` to use `count = length(var.public_subnets)` and place one NAT per public subnet. Roughly 3× the cost.

### `ecr`

| Resource | Purpose |
|---|---|
| `aws_ecr_repository.main` | Repository with AES-256 encryption and `scan_on_push` toggle. |
| `aws_ecr_lifecycle_policy.main` | Retains the most recent 30 images and expires the rest. |
| `aws_ecr_repository_policy.main` | Grants the current AWS account read/write to the repository. |

Outputs: `repository_url`, `repository_arn`, `repository_name`, `registry_id`.

## Bootstrap procedure (chicken-and-egg)

The S3 bucket and DynamoDB table referenced by `backend.tf` are created **by this same configuration**. Terraform cannot use a backend that does not yet exist, so the very first run uses local state and the backend block is migrated in afterwards.

1. **Configure AWS credentials** so the `aws` provider can authenticate.

   ```bash
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_DEFAULT_REGION=us-west-2
   # or: aws configure
   ```

2. **First apply with local state** (the `backend "s3"` block in `backend.tf` stays commented out).

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

   This creates the S3 bucket, the DynamoDB lock table, the VPC, and the ECR repository. State is written to a local `terraform.tfstate` file.

3. **Enable the remote backend.** Open `backend.tf` and uncomment the `terraform { backend "s3" { ... } }` block. If you used a different `state_bucket_name` than the default, update both the variable and the `bucket = "..."` line in `backend.tf` to match.

4. **Migrate the local state into S3.**

   ```bash
   terraform init -migrate-state
   ```

   Terraform asks `Do you want to copy existing state to the new backend?` — answer `yes`. From this point on, state lives in S3 and is locked through DynamoDB.

5. **Subsequent changes** are normal:

   ```bash
   terraform plan
   terraform apply
   ```

## Common commands

| Command | What it does |
|---|---|
| `terraform fmt -recursive` | Re-formats all `.tf` files to canonical style. |
| `terraform init` | Downloads providers and (re-)initializes the backend. |
| `terraform validate` | Static check of the configuration. |
| `terraform plan` | Dry-run; shows what would change. |
| `terraform apply` | Applies the diff after confirmation. |
| `terraform destroy` | **Tears everything down** (see warning below). |

### Destroying

`terraform destroy` will try to delete the S3 bucket containing your remote state, which is the same state that Terraform is currently using. The clean order is:

1. **First**, switch back to local state so destroying the bucket does not pull the rug out from under Terraform: re-comment the `backend "s3"` block in `backend.tf` and run `terraform init -migrate-state` (answers `yes` to copy state back to local).
2. **Then** run `terraform destroy`.
3. AWS will refuse to delete the bucket if it still contains state-file versions; either empty the bucket manually first (`aws s3 rm s3://<bucket> --recursive` and delete all object versions) or add `force_destroy = true` to `aws_s3_bucket.tfstate` before destroying. Use `force_destroy` carefully — it permanently deletes every state version.

## Configuration

All inputs have sensible defaults in `variables.tf`. Override with `-var` flags or a `terraform.tfvars` file. The most likely thing to change:

| Variable | Default | Notes |
|---|---|---|
| `state_bucket_name` | `eugenkhudoliiv-tfstate-lesson-5` | **Must be globally unique across all of AWS.** Change before first apply if the default is taken. |
| `aws_region` | `us-west-2` | Must match `availability_zones`. |
| `vpc_cidr_block` | `10.0.0.0/16` | Public subnets `.1–.3.0/24`, private `.4–.6.0/24`. |
| `ecr_repository_name` | `lesson-5-ecr` | |
