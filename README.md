# DemoTerraform

## ECS Fargate をTerraformで作成
## 実行環境
- Terraform/v1.0.8
- aws-cli/2.2.43 
- Python/3.9.7
## 実行方法
aws cliで使用するAWSで環境の設定をしておいてください。

ec2の踏み台サーバーの鍵はec2/key内に
```ssh-keygen```
で作成するか、すでに作成した公開鍵を登録してください。

```
terraform init
terraform plan
terraform apply
```
## 構成図
![aws](https://user-images.githubusercontent.com/5231283/138271599-7e3ce3e3-32ba-4526-aa61-1d6e74f52c37.png)

