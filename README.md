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
で作成してください。

```
terraform init
terraform plan
terraform apply
```
## 構成図
![aws](https://user-images.githubusercontent.com/5231283/137597998-47eafc0b-a545-42c5-ac65-339f4a35593d.png)
