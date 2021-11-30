# cat $ENV_file | #!/bin/bash
APP_NAME=$2
# 行数カウンタを初期化
line_no=1

# read コマンドで読み取れなくなるまでループ
while read LINE
do
  KEY=${LINE%%=*}
  VALUE=${LINE#*=}

  if [ -n "$VALUE" ]; then
  echo "excuted aws ssm put-parameter --type SecureString --name "/$APP_NAME/$KEY" --value "$VALUE"  --overwrite"
  aws ssm put-parameter --type SecureString --name "/$APP_NAME/$KEY" --value "$VALUE"  --overwrite 
  fi

  line_no=`expr $line_no + 1`

done <$1

exit 0