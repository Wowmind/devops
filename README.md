# DevOps Challenge

Flask microservice on AWS ECS Fargate — provisioned with Terraform, containerised with Docker, delivered via GitHub Actions. Designed for AWS Free Tier.

---

## Structure

```
devops-challenge/
├── app/
│   ├── main.py            Flask API  →  /  /health  /info
│   ├── requirements.txt
│   └── Dockerfile         Multi-stage Alpine build
│
├── modules/
│   └── infrastructure/    Single module — all AWS resources
│       ├── main.tf        VPC + ECR + CloudWatch + ECS (all here)
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── locals.tf
│
├── root/                  Root module — calls infrastructure module
│   ├── main.tf            module "infrastructure" { ... }
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf       S3 backend + AWS provider
│   └── locals.tf
│
├── .github/workflows/
│   └── deploy.yml         test → build → tf apply → ecs deploy
├── bootstrap.sh           One-time AWS setup
└── README.md
```

---

## Architecture

```
GitHub push → main
      │
      ▼
GitHub Actions
  [test] → [build & push ECR] → [terraform apply] → [ecs deploy]
                                        │
                              module "infrastructure"
                              ├── VPC (2 public subnets)
                              ├── ECR (image registry)
                              ├── CloudWatch (logs + alarms)
                              └── ECS Fargate (cluster + service + task)
```

---

## Design Decisions

- **Single infrastructure module** — VPC, ECR, ECS, and CloudWatch live in one `main.tf`. Clean, no over-engineering.
- **Fargate** — no EC2 instances to manage. 0.25 vCPU / 512 MB = minimum cost.
- **Public subnets, no NAT Gateway** — saves ~$32/month. Fargate tasks get a public IP directly.
- **No ALB** — saves ~$16/month. Public IP is sufficient for evaluation.
- **Image tag = git SHA** — every build is traceable; rollback is one `terraform apply -var image_tag=<sha>`.

---

## Cost (Free Tier)

| Resource | Free Tier | After |
|---|---|---|
| ECS Fargate 0.25vCPU/512MB | 750 hrs/mo | ~$8/mo |
| ECR < 500MB | 500MB free | $0.10/GB |
| CloudWatch | 5GB / 10 alarms free | minimal |
| S3 + DynamoDB | free | negligible |

**Within free tier: $0/month**

---

## Limitations & Improvements

| Limitation | Improvement |
|---|---|
| HTTP only | Add ACM + ALB HTTPS |
| Single task | `desired_count = 2` + ALB for HA |
| Public IP changes on redeploy | ALB with stable DNS |
| Long-lived IAM keys | GitHub OIDC → IAM role |
| No auto-scaling | ECS Application Auto Scaling |
| No alert routing | SNS → email/Slack on CloudWatch alarms |
