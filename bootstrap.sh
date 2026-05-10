#!/usr/bin/env bash
# bootstrap.sh — run ONCE before first git push
# Creates S3 state bucket, DynamoDB lock table, CI/CD IAM user
set -euo pipefail

PROJECT="devops-challenge"
REGION="us-east-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${PROJECT}-tf-state-${ACCOUNT}"
TABLE="terraform-state-locks"
USER="${PROJECT}-ci"

echo "[1/4] S3 state bucket: $BUCKET"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null || true
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "[2/4] DynamoDB lock table: $TABLE"
aws dynamodb create-table --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region "$REGION" 2>/dev/null || true

echo "[3/4] IAM user: $USER"
aws iam create-user --user-name "$USER" 2>/dev/null || true
for P in AmazonECS_FullAccess AmazonEC2ContainerRegistryFullAccess AmazonVPCFullAccess CloudWatchFullAccess IAMFullAccess; do
  aws iam attach-user-policy --user-name "$USER" --policy-arn "arn:aws:iam::aws:policy/$P"
done
aws iam put-user-policy --user-name "$USER" --policy-name TerraformState --policy-document "{
  \"Version\":\"2012-10-17\",\"Statement\":[
    {\"Effect\":\"Allow\",\"Action\":[\"s3:*\"],\"Resource\":[\"arn:aws:s3:::$BUCKET\",\"arn:aws:s3:::$BUCKET/*\"]},
    {\"Effect\":\"Allow\",\"Action\":[\"dynamodb:GetItem\",\"dynamodb:PutItem\",\"dynamodb:DeleteItem\"],\"Resource\":\"arn:aws:dynamodb:$REGION:$ACCOUNT:table/$TABLE\"}
  ]}"

echo "[4/4] Generating access keys"
KEYS=$(aws iam create-access-key --user-name "$USER")
AK=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['AccessKeyId'])")
SK=$(echo "$KEYS" | python3 -c "import sys,json; print(json.load(sys.stdin)['AccessKey']['SecretAccessKey'])")

echo "

   Bootstrap complete. Next steps:                         
                                                          
   1. GitHub → Settings → Secrets → Actions:              
      AWS_ACCESS_KEY_ID     = $AK
      AWS_SECRET_ACCESS_KEY = $SK
                                                           
   2. Update root/providers.tf:                            
      bucket = \"$BUCKET\"
"
