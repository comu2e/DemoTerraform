#! /bin/bash
set -euC

# set enviroment value into aws ssm parameter store.
#usage
# cp .env.example .env.dev
# input env value .env.dev
# sh aws.s  app_name .env.dev

APP_NAME=$1
# initialize raw count
line_no=1

while read LINE
do
  KEY=${LINE%%=*}
  VALUE=${LINE#*=}
  #if $VALUE is not set or not filled.
  if [[ -n "$VALUE" ]]; then
  #execute aws cli command.
  echo "excuted aws ssm put-parameter --type SecureString --name "/$APP_NAME/$KEY" --value "$VALUE"  --overwrite"
  aws ssm put-parameter --type SecureString --name "/$APP_NAME/$KEY" --value "$VALUE"  --overwrite 
  fi

  line_no=`expr $line_no + 1`

done <$2

exit 0