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

migrate:
	@${CD} && \
	terraform init -migrate-state

apply:
	@${CD} && \
	terraform apply
		
destroy:
	@${CD} && \
	terraform destroy
