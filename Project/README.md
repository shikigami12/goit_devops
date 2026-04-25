# Lesson 8 — CI/CD with Jenkins + Argo CD

Full CI/CD pipeline: Jenkins builds the Django Docker image with Kaniko, pushes to ECR, updates the Helm chart tag in Git, and Argo CD auto-syncs the deployment to EKS.

## CI/CD Flow

```text
Git push
   │
   ▼
Jenkins Pipeline (Kubernetes Agent)
   ├─ kaniko: build & push → ECR (project-django:BUILD_NUMBER)
   └─ git:    sed values.yaml → commit → push to main
                                              │
                                              ▼
                                    Argo CD detects Git change
                                              │
                                              ▼
                                    helm upgrade django-app → EKS
```

## Prerequisites

- AWS credentials with permissions for VPC, EKS, ECR, S3, DynamoDB, IAM.
- Terraform ≥ 1.6, AWS CLI v2, kubectl ≥ 1.30.

## Bootstrap

```bash
# 1. First apply — creates state bucket, VPC, ECR, EKS cluster.
#    backend.tf must stay commented for this step.
cd Project
terraform init
terraform apply -target=module.s3_backend -target=module.vpc -target=module.ecr -target=module.eks

# 2. Migrate state to S3 (uncomment backend block in backend.tf, then):
terraform init -migrate-state

# 3. Configure kubectl.
aws eks update-kubeconfig --name project-eks --region us-west-2
kubectl get nodes

# 4. Apply Jenkins + Argo CD.
terraform apply

# 5. Get Jenkins URL.
terraform output jenkins_url_command | bash

# 6. Get Argo CD URL and initial password.
terraform output argocd_server_command | bash
terraform output argocd_initial_password_command | bash
```

## Jenkins setup (post-install)

1. Open Jenkins URL, log in with `admin` / the password set in `var.jenkins_admin_password`.
2. Create a Multibranch Pipeline job pointing at this repo.
3. Add credentials:
   - `ecr-registry-url` — String credential: `<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com`
   - `github-credentials` — Username + Password: GitHub username + personal access token (needs `repo` scope)
4. Create the ECR auth secret in the jenkins namespace:

   ```bash
   TOKEN=$(aws ecr get-login-password --region us-west-2)
   kubectl create secret docker-registry ecr-credentials \
     --docker-server=<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com \
     --docker-username=AWS \
     --docker-password="${TOKEN}" \
     -n jenkins
   ```

5. Update `git_repo_url` in `main.tf` to your actual repo URL and `terraform apply`.

## Argo CD setup

After `terraform apply`, Argo CD Application `django-app` is created automatically.
It watches `Project/charts/django-app` on `main` and auto-syncs on every push.

## Layout

```text
Project/
├── main.tf, backend.tf, outputs.tf
├── Jenkinsfile
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   ├── eks/               ← includes aws_ebs_csi_driver.tf
│   ├── jenkins/           ← Helm release + values.yaml
│   └── argo_cd/           ← Helm release + app-of-apps chart
└── charts/django-app/     ← Helm chart synced by Argo CD
```

## RDS Module

The `modules/rds` module provisions either an Aurora PostgreSQL cluster or a plain RDS PostgreSQL instance, controlled by `use_aurora`.

### Usage example

```hcl
module "rds" {
  source = "./modules/rds"

  identifier     = "my-db"
  use_aurora     = false          # true → Aurora cluster, false → RDS instance
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  vpc_cidr_block = "10.0.0.0/16"
  db_name        = "mydb"
  db_username    = "admin"
  db_password    = var.db_password
}
```

### Variables

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `use_aurora` | bool | `false` | `true` → Aurora cluster; `false` → RDS instance |
| `identifier` | string | `"project-db"` | Base name for all RDS resources |
| `engine` | string | `"postgres"` | Engine for plain RDS |
| `engine_version` | string | `"15.4"` | Engine version for plain RDS |
| `aurora_engine` | string | `"aurora-postgresql"` | Engine for Aurora |
| `aurora_engine_version` | string | `"15.4"` | Engine version for Aurora |
| `instance_class` | string | `"db.t3.micro"` | DB instance class |
| `allocated_storage` | number | `20` | GiB (plain RDS only) |
| `multi_az` | bool | `false` | Multi-AZ (plain RDS only) |
| `db_name` | string | `"devops"` | Initial database name |
| `db_username` | string | — | Master username (sensitive) |
| `db_password` | string | — | Master password (sensitive) |
| `db_port` | number | `5432` | Database port |
| `db_parameter_group_family` | string | `"postgres15"` | PG family for plain RDS |
| `aurora_parameter_group_family` | string | `"aurora-postgresql15"` | PG family for Aurora |
| `log_statement` | string | `"none"` | PostgreSQL log_statement param |
| `work_mem` | string | `"4096"` | work_mem in kB |
| `max_connections` | string | `"100"` | max_connections (plain RDS only) |

### Switching modes

- **Switch to Aurora:** set `use_aurora = true` in `main.tf`
- **Change engine version:** update `engine_version` / `aurora_engine_version` and the matching `*_parameter_group_family` (e.g. `postgres16`, `aurora-postgresql16`)
- **Change instance class:** set `instance_class` (e.g. `db.t3.small`, `db.r6g.large` for Aurora)
- **Multi-AZ for plain RDS:** set `multi_az = true`

## Monitoring (Prometheus + Grafana)

Deployed via `modules/monitoring` using the `kube-prometheus-stack` Helm chart into the `monitoring` namespace. Includes Prometheus, Grafana, AlertManager, and Node Exporter.

```bash
# Verify all monitoring pods are running
kubectl get all -n monitoring

# Access Grafana (admin / admin by default)
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# Open http://localhost:3000

# Access Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring
# Open http://localhost:9090

# Or use terraform outputs
terraform output grafana_portforward_command | bash
```

Grafana comes pre-loaded with dashboards for Kubernetes cluster metrics, node metrics, and pod CPU/memory. The HPA on `django-app` (2–6 replicas at 70% CPU) is visible in the workload dashboards.

## Django Application

The Django app lives in `Django/` and is built by the Jenkins pipeline.

```bash
# Local development
cd Django
docker compose up

# App is available at http://localhost (via nginx proxy)
# API health check: GET / → JSON with db reachability status
```

## Deploy checklist

```bash
# 1. Bootstrap state backend + VPC + ECR + EKS first
terraform init
terraform apply -target=module.s3_backend -target=module.vpc -target=module.ecr -target=module.eks

# 2. Migrate state
terraform init -migrate-state

# 3. Apply everything else (Jenkins, Argo CD, RDS, monitoring)
terraform apply

# 4. Verify namespaces
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring

# 5. Jenkins port-forward
kubectl port-forward svc/jenkins 8080:8080 -n jenkins

# 6. Argo CD port-forward
kubectl port-forward svc/argocd-server 8081:443 -n argocd

# 7. Grafana port-forward
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

## Cleanup

```bash
terraform destroy
```
