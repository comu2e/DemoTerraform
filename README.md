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
![aws](https://user-images.githubusercontent.com/5231283/138276160-a7867846-7129-49c8-882b-8be710066cf8.png)
