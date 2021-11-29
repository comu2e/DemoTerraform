# usage:
# $ make init ENV=(dev or prod)
# $ make plan ENV=(dev or prod)
# $ make apply ENV=(dev or prod)
# args:
# ENV: Direvtory to run apply or init in.

REGION = ap-northeast-1
ENV = $1
SCOPE := src/${ENV} 
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
