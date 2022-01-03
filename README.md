# DemoTerraform
## Concept
Construct AWS ECS Fargate with terraform sample.

## Environment
- Terraform/v1.0.11
- aws-cli/2.2.43 
___

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
    │   ├── compute:db bastion instance.
    │   │   └── ec2
    │   ├── db:DB storage 
    │   ├── ecs:web/app server.
    │   │   └── template
    │   ├── elb:load balancer
    │   ├── iam
    │   ├── network:AWS Network,vpc/route table/internet gateway.
    │   ├── redis:use for app-worker.
    │   ├── security:Security groups.
    │   └── worker:worker ecs fargate.
    └── prod
```

___

## Execution method

```
$ cp .env.example .env
write value into .env.
$ make s3_tfbackend SRC=dev or prod
$ make plan SRC=dev or prod
$ make apply SRC=dev or prod

$ make outputs SRC=dev or prod
$ make ssm_put SRC=dev or prod

```

___


## Detail (Initial set up)

### ①　Create File for each environment.(dev /prod/ staging)
Create main, output, variables.tf, backend.tf of environment in src directory.

Set app_name in variables.tf so that you can see the app name and environment name.

Differences in each environment are managed in variables.tf.

### ②　Create S3 bucket for tfstate.

```
$ make s3_tfbackend
```

### ③　Set up Parameter store.
Store secret information in AWS Parameter store.

* ```ssh_put.sh``` is prepared.

 #### Usage ssh_put.sh
①copy .env.example

 ```cp .env.example .env.dev```

② Registe file to```.gitignore```

③ Write value into ```.env```.

（Note that REDIS_HOST, DB_HOST, etc. are values that appear after make apply)

④ 
```
 $ sh ssh_put.sh File name with environment variables {string similar to $ app_name set in src / variables.tf} 
 ```
  
  Example 
  
  ```
  Env file name with environment variables set up in .env.dev
  
  if app_name is app_dev,

  $ sh ssh_put.sh app_dev .env.dev  
  ```



The following commands are executed for the environment variables.
```
$ aws ssm put-parameter --type SecureString --name "/${app_nameを入力}/該当するキー" --value "該当する値"  --overwrite
```


### ④ Make ssh key.


- Please set the environment on AWS used by aws cli.
- The key to the ec2 bastion server is in module / compute / template
Create it with `` `ssh-keygen``` or register the public key you have already created.

### ⑤　etc.


- Log can be confirmed in CloudFormation, but in order to improve the ease of confirmation, Log can be sent to Grafana Cloud.
If you want to use it, please set up a Grafana Cloud account.

- SES is set manually.

- Since each environment consumes about 3 EIPs, please apply to AWS to lift the upper limit of EIPs when building 2 or more environments.

- Pushed each DockerImage(PHP/Nginx) container to ECR repository.


## Diagram
![aws](https://user-images.githubusercontent.com/5231283/143753728-45549b82-2098-492f-a014-6b23c05f510f.png)

## Todo 
- https conversion(ALB,Route53)
- CloudFront
- Refactoring(Cloudmap is not necessary at this time.)
- Frontend Container
- Combine the above methods into a shell script.
