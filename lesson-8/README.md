# Lesson 8 — CI/CD with Jenkins + Argo CD

Full CI/CD pipeline: Jenkins builds the Django Docker image with Kaniko, pushes to ECR, updates the Helm chart tag in Git, and Argo CD auto-syncs the deployment to EKS.

## CI/CD Flow

```
Git push
   │
   ▼
Jenkins Pipeline (Kubernetes Agent)
   ├─ kaniko: build & push → ECR (lesson-8-django:BUILD_NUMBER)
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
cd lesson-8
terraform init
terraform apply -target=module.s3_backend -target=module.vpc -target=module.ecr -target=module.eks

# 2. Migrate state to S3 (uncomment backend block in backend.tf, then):
terraform init -migrate-state

# 3. Configure kubectl.
aws eks update-kubeconfig --name lesson-8-eks --region us-west-2
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
It watches `lesson-8/charts/django-app` on `main` and auto-syncs on every push.

## Layout

```
lesson-8/
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

## Cleanup

```bash
terraform destroy
```
