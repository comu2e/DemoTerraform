# usage:
# $ make ecr_repo
# $ make init-(dev or prod or etc.)
# $ make plan-(dev or prod or etc.)
# $ make apply-(dev or prod or etc.)
include .env
QUEST := $0
SRC := $1
ARG2 := $2
ROOT := src
SCOPE := ${ROOT}/${SRC}
CD = [[ -d $(SCOPE) ]] && cd $(SCOPE)

# aws cliは入っておく。
ecr_repo:
	aws ecr create-repository --repository-name $(APP_NAME)-app && \
	aws ecr create-repository --repository-name $(APP_NAME)-nginx

ssm_store:
	sh ssm_put.sh $(APP_NAME) .env

init:
	@${CD} && \
	terraform init

plan:
	@${CD} && \
	terraform plan

# Make migrate if S3 bucket name is changed.
migrate:
	@${CD} && \
	terraform init -migrate-state

# Make resources by terraform
apply:
	@${CD} && \
	terraform apply

# Refresh tfstate if created resources are changed by manually.
refresh:
	@${CD} && \
	terraform refresh

# Make state list of resources.
list:
	@${CD} && \
	terraform state list

# Destroy terraform resources.
destroy:
	@${CD} && \
	terraform destroy

