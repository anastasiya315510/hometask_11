#### 1. Prerequisites

Terraform installed (terraform -version).

AWS credentials configured (via aws configure, environment variables, or provider block).

An existing key pair in AWS to SSH into the instance (or we can let Terraform create one).


#### 2. Example Terraform Code (main.tf)

This creates:

An EC2 instance

A security group to allow SSH (port 22)

### 3. Run Terraform
`
terraform init      # downloads AWS provider plugin

terraform plan      # shows what will be created

terraform apply     # creates resources, confirm with "yes"


`