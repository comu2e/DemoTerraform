# usage:
# $ make init-(dev or prod or etc.)
# $ make plan-(dev or prod or etc.)
# $ make apply-(dev or prod or etc.)
SCOPE := src
CD = [[ -d $(SCOPE) ]] && cd $(SCOPE)

.PHONY: all init

all:
	@more Makefile

init-%:
	@[[ -d $(SCOPE)/${@:init-%=%} ]] && \
	cd $(SCOPE)/${@:init-%=%}  && \
	terraform init

plan-%:
	@[[ -d $(SCOPE)/${@:plan-%=%} ]] && \
	cd $(SCOPE)/${@:plan-%=%}  && \
	terraform plan

migrate-%:
	@[[ -d $(SCOPE)/${@:migrate-%=%} ]] && \
	cd $(SCOPE)/${@:migrate-%=%}  && \
	terraform init -migrate-state

apply-%:
	@[[ -d $(SCOPE)/${@:apply-%=%} ]] && \
	cd $(SCOPE)/${@:apply-%=%}  && \
	terraform apply
		
destroy-%:
	@[[ -d $(SCOPE)/${@:destroy-%=%} ]] && \
	cd $(SCOPE)/${@:destroy-%=%}  && \
	terraform destroy
