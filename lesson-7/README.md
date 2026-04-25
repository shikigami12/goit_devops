# Lesson 7 — Kubernetes + Helm

Provisions an EKS cluster with Terraform, builds and pushes the lesson-4 Django image to ECR, and deploys it via a Helm chart with HPA-driven autoscaling (2–6 pods @ 70% CPU).

## Prerequisites

- AWS credentials with permissions to create VPC, EKS, ECR, S3, DynamoDB.
- `terraform >= 1.6`, AWS CLI v2, `kubectl >= 1.30`, `helm >= 3.14`, `docker`.

## Bootstrap & deploy

```bash
# 1. First apply — creates state bucket, lock table, VPC, ECR, EKS cluster.
#    backend.tf is commented for this step.
cd lesson-7
terraform init
terraform apply

# 2. Migrate state to S3 backend.
#    Uncomment the backend block in backend.tf, then:
terraform init -migrate-state

# 3. Push the Django image to ECR.
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin "${ACCOUNT}.dkr.ecr.us-west-2.amazonaws.com"
docker build --platform=linux/amd64 -t lesson-7-django:v1 ../lesson-4
docker tag lesson-7-django:v1 "${ECR_URL}:v1"
docker push "${ECR_URL}:v1"

# 4. Configure kubectl.
aws eks update-kubeconfig --name lesson-7-eks --region us-west-2
kubectl get nodes   # should list 2 t3.medium nodes

# 5. Install metrics-server (HPA prerequisite, not bundled with EKS).
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system rollout status deploy/metrics-server

# 6. Install the chart.
helm install django ./charts/django-app \
  --set image.repository="${ECR_URL}" \
  --set image.tag=v1

# 7. Verify.
kubectl get svc django-django-app   # EXTERNAL-IP is the LoadBalancer DNS
kubectl get hpa                     # shows current/target CPU and replica count
```

## Layout

```
lesson-7/
├── main.tf, backend.tf, outputs.tf
├── modules/{s3-backend,vpc,ecr,eks}
└── charts/django-app/{Chart.yaml,values.yaml,templates/}
```

## Cleanup

```bash
helm uninstall django
terraform destroy
```

`terraform destroy` removes the EKS cluster, NAT gateway, VPC, and ECR. The S3 bucket and DynamoDB table are also destroyed; if state was migrated to S3, comment `backend.tf` and run `terraform init -migrate-state` first to pull state back to local before destroying.
