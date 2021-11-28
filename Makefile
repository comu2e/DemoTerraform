# usage:
# $ make terraform ENV=(dev or prod) ARGS=init
# $ make terrafomr ENV=(dev or prod) ARGS=apply
# args:
# ENV: Direvtory to run apply or init in.
# ARGS:Specify terraform command.
# BUCKET_NAME : tfstate Storage.
# PROFILE : AWS profile
REGION = ap-northeast-1
CD = [[ -d env/${ENV} ]] && cd env/${ENV}
ENV = $1

init:
	@${CD} && \
		terraform init

migrate:
	@${CD} && \
		terraform init -migrate-state

apply:
	@${CD} && \
		terraform apply

