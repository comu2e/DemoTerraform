# usage:
# $ make ecr_repo
# $ make init SRC=(dev or prod or etc.)
# $ make plan SRC=(dev or prod or etc.)
# $ make apply SRC=(dev or prod or etc.)
include .env
SRC := $1
ROOT := src
SCOPE := ${ROOT}/${SRC}
CD = [[ -d $(SCOPE) ]] && cd $(SCOPE)
ENV__PROD_FILE := .env.production
TF_STATE_BUCKET := tfstate-${APP_NAME}-${SRC}
TR_INIT_OPTION := -reconfigure -reconfigure -backend-config="bucket=${TF_STATE_BUCKET}"  \
           -backend-config="key=terraform.tfstate.${SRC}" \
          -backend-config="region=ap-northeast-1"

s3_tfbackend:
	  # S3 bucket作成 versioning機能追加
		aws s3 mb s3://${TF_STATE_BUCKET}&& \
		aws s3api put-bucket-versioning --bucket ${TF_STATE_BUCKET} --versioning-configuration Status=Enabled

ecr_repo:
	aws ecr create-repository --repository-name $(APP_NAME)-app && \
	aws ecr create-repository --repository-name $(APP_NAME)-nginx

ssm_put:
	sh ./settings/bin/ssm_put.sh $(APP_NAME) .env

init:
	@${CD} && \
	terraform init ${TR_INIT_OPTION}
	
plan:
	@${CD} && \
	terraform plan

# Make migrate if S3 bucket name is changed.
migrate:
	@${CD} && \
	terraform init -migrate-state ${TR_INIT_OPTION}
# Make resources by terraform
apply:
	@${CD} && \
	terraform init ${TR_INIT_OPTION} && \
	terraform apply

# Refresh tfstate if created resources are changed by manually.
refresh:
	@${CD} && \
	terraform refresh

# Make state list of resources.
list:
	@${CD} && \
	terraform init ${TR_INIT_OPTION} && \
	terraform state list

# Destroy terraform resources.
destroy:
	@${CD} && \
	terraform init ${TR_INIT_OPTION} && \
	terraform destroy

outputs:
	${CD} && \
	terraform output -json | jq -r '"DB_HOST=\(.db_endpoint.value)"' > .env.production && \
	terraform output -json | jq -r '"REDIS_HOST=\(.redis_hostname.value[0].address)"' >> .env.production && \
	terraform output -json | jq -r '"SUBNETS=\(.db_subnets.value)"' >> .env.production &&\
	terraform output -json | jq -r '"SECURITY_GROUPS=\(.db_security_groups.value)"' >> .env.production
