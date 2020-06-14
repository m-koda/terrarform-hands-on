# Terraformハンズオン

## 概要
- VPCとパブリックサブネットを作成
- 上記で作成したパブリックサブネットにEC2を作成する

## 手順

### 手順(1)
AWSコンソールからterraform用のIAMユーザーを作成する
- ユーザー名：terraform-hands-on
- アクセスの種類：プログラムによるアクセスのみチェック
- 既存のポリシーを直接アタッチ：PowerUserAccess

### 手順(2)
手順(1)で作成したIAMユーザーのアクセスキー、シークレットキーを使うようにterraformを設定する

```bash
$ export AWS_ACCESS_KEY_ID="accesskey"
$ export AWS_SECRET_ACCESS_KEY="secretkey"
```

### 手順(3)
AWSプロバイダーの設定し、`terraform init`を実行する

・provider.tf

```
provider "aws" {
  region  = "ap-northeast-1"
}
```

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "aws" (hashicorp/aws) 2.66.0...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 2.66"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### 手順(4)
[gitignore.io](https://www.toptal.com/developers/gitignore)の出力通りに.gitignoreを設定する

・.gitignore
```
# Created by https://www.toptal.com/developers/gitignore/api/terraform
# Edit at https://www.toptal.com/developers/gitignore?templates=terraform

### Terraform ###
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log

# Ignore any .tfvars files that are generated automatically for each Terraform run. Most
# .tfvars files are managed as part of configuration and so should be included in
# version control.
#
# example.tfvars

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
# example: *tfplan*

# End of https://www.toptal.com/developers/gitignore/api/terraform
.envrc
```

### 手順(5)
VPCを作成する

・vpc.tfの作成
```
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

・`terraform fmt`, `terraform validate`, `terraform plan`の実施
```bash
$ terraform validate
Success! The configuration is valid.

$ terraform fmt
provider.tf
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.


------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                              = (known after apply)
      + assign_generated_ipv6_cidr_block = false
      + cidr_block                       = "10.0.0.0/16"
      + default_network_acl_id           = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_group_id        = (known after apply)
      + dhcp_options_id                  = (known after apply)
      + enable_classiclink               = (known after apply)
      + enable_classiclink_dns_support   = (known after apply)
      + enable_dns_hostnames             = (known after apply)
      + enable_dns_support               = true
      + id                               = (known after apply)
      + instance_tenancy                 = "default"
      + ipv6_association_id              = (known after apply)
      + ipv6_cidr_block                  = (known after apply)
      + main_route_table_id              = (known after apply)
      + owner_id                         = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

・`terraform apply`の実施

### 手順(6)
IGWの作成

・vpc.tfに以下を追加する
```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}
```

・`terraform fmt`, `terraform validate`, `terraform plan`, `terraform apply`の実施

### 手順(7)
パブリックサブネットとルートテーブルの作成

・vpc.tfに以下を追記する

```
resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_route_table" "public-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-a.id
}
```

### 手順(8)
AWSコンソールからキーペアを作成する

### 手順(9)
手順(7)で作成したパブリックサブネットにEC2をたてる

・以下の内容でsecurity_group.tfを作成する
```
resource "aws_security_group" "terraform-hands-on" {
  vpc_id = aws_vpc.main.id
  name   = "terraform-hands-on"

  tags = {
    Name = "terraform-hands-on"
  }
}

resource "aws_security_group_rule" "in_ssh" {
  security_group_id = aws_security_group.terraform-hands-on.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.terraform-hands-on.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}
```

・以下の内容でec2.tfを作成する
```
resource "aws_instance" "example" {
  ami                    = data.aws_ami.amazon-linux-2.image_id
  vpc_security_group_ids = [aws_security_group.terraform-hands-on.id]
  subnet_id              = aws_subnet.public-a.id
  key_name               = "terraform-hands-on"
  instance_type          = "t2.micro"

  tags = {
    Name = "terraform-hands-on"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
```

・vpc.tfのaws_subnet(public-a)に以下を追加する
```
map_public_ip_on_launch = true
```

・outputs.tfを以下の内容で作成する
```
output "ec2-public-ip" {
  value = aws_instance.example.public_ip
}
```

・`terraform fmt`, `terraform validate`, `terraform plan`, `terraform apply`の実施

### 手順(10)
作成したリソースの削除

・`terrform destroy`の実施

※AWSコンソールから作成したものはAWSコンソールから削除してください