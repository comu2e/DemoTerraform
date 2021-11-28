
cat $ENV_file | aws ssm put-parameter --type SecureString --overwrite --name "/${app_nameを入力}/該当するキー" --value "該当する値" --allowed-pattern "\d{1,4}" --value 100
