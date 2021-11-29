# DemoTerraform
## 概要
ECS Fargate をTerraformで作成したサンプルになります。

## 実行環境
- Terraform/v1.0.11
- aws-cli/2.2.43 
- Python/3.9.7
## 初期設定
### ①　環境ごとのファイル作成

envディレクトリ内に環境のmain,output,variables.tf,backend.tfを作成する。

各環境の差分はvariablesで管理するようにしている。

tfstateのリモート保存先設定(S3荷バケット作成)

### ②　S3 bucket作成：
variables.tfのapp_nameでアプリ名と環境名がわかるように設定しておく。
```
$ aws s3 mb s3://tfstate-${var.app_name} 
```
### ③　Parameter storeへの値設定
- 機密情報などはAWSのParameterStoreを使用してください。
  （RDSのデータベース、ユーザー名、パスワードの管理に今回は使用しています）
```
$ aws ssm put-parameter --type SecureString --name "/${app_nameを入力}/該当するキー" --value "該当する値"  --overwrite
```
（Todo:.env.*に環境変数を記載してshでaws cliを実行できるようにする。）

### ④　秘密鍵の作成

- aws cliで使用するAWSで環境の設定をしておいてください。
- ec2の踏み台サーバーの鍵はmodule/compute/template内に
```ssh-keygen```で作成するか、すでに作成した公開鍵を登録してください。

- ECRにDockerImageをプッシュしておく。
今回のサンプルは下記のDocker(nginx/php-fpm)の簡素な構成としています。
https://github.com/comu2e/nginx-php-Sample
### ⑤　その他

- LogはCloudFormationで確認できますが、確認のしやすさを高めるためにGrafanaCloudにLogを流せるようにしています。
使用したい場合はGrafanaCloudのアカウント設定をしてください。
- SESは手動で設定しています。

## 実行方法

```
$ make init ENV=dev 
$ make plan ENV=dev
$ make apply ENV=dev
```
変更時は上記のDockerfile,confファイルなどを使用用途に合わせて変更するとともに、
container-defition.jsonを変更してください。

## 構成図
![aws](https://user-images.githubusercontent.com/5231283/143753728-45549b82-2098-492f-a014-6b23c05f510f.png)

## Todo 
- https化(ALB,Route53の設定)
- Cacheサービスの選定(SQS/Elastic Cacheなど)
- CloudFront(必要に応じて）
- CI/CD(nginx-phpfpmレポジトリ)
- リファクタリング(Cloudmapは現時点では不要)
- Frontendの追加
