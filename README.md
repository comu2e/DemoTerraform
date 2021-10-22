# DemoTerraform

## 概要
ECS Fargate をTerraformで作成したサンプルになります。


## 実行環境
- Terraform/v1.0.8
- aws-cli/2.2.43 
- Python/3.9.7

## 実行方法
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
![aws](https://user-images.githubusercontent.com/5231283/138431637-82e7a65f-3cbb-4fb2-9b72-287ac4e830aa.png)
