# usage:
# $ make terraform ENV=(dev or prod) ARGS=init
# $ make terrafomr ENV=(dev or prod) ARGS=apply
# args:
# ENV: Direvtory to run apply or init in.
# ARGS:Specify terraform command.
# BUCKET_NAME : tfstate Storage.
# PROFILE : AWS profile
BUCKET_NAME = hoge
REGION = ap-northeast-1
CD = [[ -d env/${ENV} ]] && cd env/${ENV}
ENV = $1
ARGS = $2
PROFILE = $3

terraform:
	@${CD} && \
		terraform ${ARGS}

remote-enable:
	@${CD} && \
		terraform remote config \
		-backend=s3 \
		-backend-config='bucket=${BUCKET_NAME}' \
		-backend-config='key=${ENV}/terraform.tfstate' \
		-backend-config='region=${REGION}' \
		-backend-config='profile=${PROFILE}'

remote-disable:
	@${CD} && \
		terraform remote config \
		-disable