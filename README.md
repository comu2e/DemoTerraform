# DemoTerraform

## 概要
ECS Fargate をTerraformで作成したサンプルになります。

＊ SESは手動で設定しています。

## 実行環境
- Terraform/v1.0.8
- aws-cli/2.2.43 
- Python/3.9.7

## 初期設定
tfstateのリモート保存先設定(S3荷バケット作成)
```
# Parameter storeへの値設定
 aws ssm put-parameter --type SecureString --overwrite --name "/${app_nameを入力}/該当するキー" --value "該当する値" --allowed-pattern "\d{1,4}" --value 100
```
## 実行方法
```make terraform ENV=dev ARGS=init
```make terraform ENV=dev ARGS=apply
```
- aws cliで使用するAWSで環境の設定をしておいてください。
- ec2の踏み台サーバーの鍵はec2/key内に
```ssh-keygen```
で作成するか、すでに作成した公開鍵を登録してください。

- ECRにDockerImageをプッシュしておく。
今回のサンプルは下記のDocker(nginx/php-fpm)の簡素な構成としています。
https://github.com/comu2e/nginx-php-Sample

変更時は上記のDockerfile,confファイルなどを使用用途に合わせて変更するとともに、
container-defition.jsonを変更してください。

- LogはCloudFormationで確認できますが、確認のしやすさを高めるためにGrafanaCloudにLogを流せるようにしています。
使用したい場合はGrafanaCloudのアカウント設定をしてください。

- 機密情報などはAWSのParameterStoreを使用してください。
  （RDSのデータベース、ユーザー名、パスワードの管理に今回は使用しています）

- terraformの環境を作成して、下記のコマンドを実行。
```
terraform init
terraform plan
terraform apply
```
## 構成図
![aws](https://user-images.githubusercontent.com/5231283/143753728-45549b82-2098-492f-a014-6b23c05f510f.png)

## Todo 
- https化(ALB,Route53の設定)
- Cacheサービスの選定(SQS/Elastic Cacheなど)
- CloudFront(必要に応じて）
- CI/CD(nginx-phpfpmレポジトリ)
- リファクタリング(Cloudmapは現時点では不要)
- Frontendの追加