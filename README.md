# DemoTerraform
## 概要
Construct AWS ECS Fargate with terraform sample.

## Environment
- Terraform/v1.0.11
- aws-cli/2.2.43 

## Architecture
```
.
|___ MakeFile:Include terraform command to apply/destroy.
├── settings
│   ├── bin
│   │   └── sessionmanager-bundle
│   │       └── bin : utilty for aws cli
│   └── template : container definition template file.
└── src
    ├── dev : AWS Environment for dev.
    ├── module: Used for dev or prod envrionment.
    │   ├── cloudmap
    │   ├── compute
    │   │   └── ec2
    │   ├── db
    │   ├── ecs
    │   │   └── template
    │   ├── elb
    │   ├── github
    │   ├── iam
    │   ├── network
    │   ├── redis
    │   ├── security
    │   └── worker
    └── prod
```



## Initial settings.
### ①　Create File for each environment.(dev /prod/ staging)

srcディレクトリ内に環境のmain,output,variables.tf,backend.tfを作成する。

variables.tfのapp_nameでアプリ名と環境名がわかるように設定しておく。

各環境の差分はvariablesで管理するようにしている。

tfstateのリモート保存先設定(S3にバケット作成)

### ②　Create S3 bucket for tfstate：
```
$ make s3_tfbackend
```
### ③　Set up Parameter store.
- 機密情報などはAWSのParameterStoreを使用してください。
  （RDSのデータベース、ユーザー名、パスワードの管理に今回は使用しています）

環境変数の登録用に```ssh_put.sh```を準備しています。

 #### ssh_put.shの使い方
環境変数を設定するのがめんどくさいので作っています。
①.env.exampleをコピー ```cp .env.example .env.dev```

② コピーしたファイルを```.gitignore```に登録

③ コピーした```.env```ファイルに値を記述。（REDIS_HOST,DB_HOSTなどはmake apply後に出てくる値なので注意）

④ ```$ sh ssh_put.sh 環境変数を設定したファイル名 {src/variables.tfに設定した$app_nameと同様の文字列} ```
  
  例
  
  ```
  環境変数を設定したenvファイル名 .env.dev
  
  $app_nameがapp_dev
  
  $ sh ssh_put.sh app_dev .env.dev  
  ```

以上

下記のコマンドを環境変数分実行しています。
```
$ aws ssm put-parameter --type SecureString --name "/${app_nameを入力}/該当するキー" --value "該当する値"  --overwrite
```


### ④　公開鍵の作成

- aws cliで使用するAWSで環境の設定をしておいてください。
- ec2の踏み台サーバーの鍵はmodule/compute/template内に
```ssh-keygen```で作成するか、すでに作成した公開鍵を登録してください。

### ⑤　その他

- LogはCloudFormationで確認できますが、確認のしやすさを高めるためにGrafanaCloudにLogを流せるようにしています。
使用したい場合はGrafanaCloudのアカウント設定をしてください。
- SESは手動で設定しています。
- １つの環境ごとにEIPを３つぐらい消費するので、２つ以上の環境を構築する場合はEIPの上限解除をAWSに申請してください。
- ECRにDockerImageをプッシュしておく。

## 実行方法

```
$ make init SRC=dev or prod
$ make plan SRC=dev or prod
$ make apply SRC=dev or prod
```
変更時は上記のDockerfile,confファイルなどを使用用途に合わせて変更するとともに、
container-defition.jsonを変更してください。

## 構成図
![aws](https://user-images.githubusercontent.com/5231283/143753728-45549b82-2098-492f-a014-6b23c05f510f.png)

## Todo 
- https化(ALB,Route53の設定)
- Cacheサービスの選定(SQS/Elastic Cacheなど)
- CloudFront(必要に応じて）
- リファクタリング(Cloudmapは現時点では不要)
- Frontendの追加
- 上記手順をシェルでまとめる。
