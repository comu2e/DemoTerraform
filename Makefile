# usage:
# $ make init-(dev or prod or etc.)
# $ make plan-(dev or prod or etc.)
# $ make apply-(dev or prod or etc.)
SRC := $1
ROOT := src
SCOPE := ${ROOT}/${SRC}
CD = [[ -d $(SCOPE) ]] && cd $(SCOPE)

.PHONY: all init

all:
	@more Makefile

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
# Make state list of resources.
list:
	@${CD} && \
	terraform state list

apply:
	@${CD} && \
	terraform apply
		
destroy:
	@${CD} && \
	terraform destroy
