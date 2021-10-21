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

 ECRにDockerImageをプッシュしておく。
今回のサンプルは下記のDocker(nginx/php-fpm)の簡素な構成としています。
https://github.com/comu2e/nginx-php-Sample

変更時は上記のDockerfile,confファイルなどを使用用途に合わせて変更するとともに、
container-defition.jsonを変更してください。


- terraformの環境を作成して、下記のコマンドを実行。
```
terraform init
terraform plan
terraform apply
```
## 構成図
![aws](https://user-images.githubusercontent.com/5231283/138276160-a7867846-7129-49c8-882b-8be710066cf8.png)
