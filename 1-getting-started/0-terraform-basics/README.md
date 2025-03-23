# Terraform Project Files Basics:

## **versions.tf** : 
Keeps Terraform and Provider versions/source information separate from infrastructure logic. For example:
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}
```

## **providers.tf** : 
Keeps provider configs/settings separate, allowing multiple providers if needed. For example:
```
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
```

If required we can even add the same provider multiple times with different alias and configs. For example:
```
provider "aws" {
  region  = "us-east-1"

  # This is optional since "default" is used by default
  profile = "default"
}

provider "aws" {
  alias   = "dev"
  region  = "us-east-1"

  # Uses the "dev" profile account details from ~/.aws/credentials file
  profile = "dev"  
}
```

### Commands For Configuring AWS Profiles:
Using profiles we can connect various AWS accounts from the same CLI.

```shell
# Command to configure a default profile
$ aws configure
    AWS Access Key ID [None]: **************
    AWS Secret Access Key [None]: ************************
    Default region name [None]: us-east-1
    Default output format [None]: json

# Command to configure a profile name sriram
$ aws configure --profile sriram
    AWS Access Key ID [None]: **************
    AWS Secret Access Key [None]: ************************
    Default region name [None]: us-east-1
    Default output format [None]: table

# These aws configure commands creates the following files:
$ ls -l ~/.aws/
total 16
-rw-------  1 sriramponangi  staff   95 15 Mar 15:36 config
-rw-------  1 sriramponangi  staff  232 15 Mar 15:30 credentials


$ cat ~/.aws/config 
[profile sriram]
region = us-east-1
output = json

[default]
region = us-east-2
output = yaml

$ cat ~/.aws/credentials 
[sriram]
aws_access_key_id = **************
aws_secret_access_key = ************************

[default]
aws_access_key_id = **************
aws_secret_access_key = ************************
```

If we want to use another profile instead of the default profile then:

**Approach-1**: Append the --profile [profile-name] flag to the aws command. For example:
```
$ aws s3 ls --profile default
$ aws s3 ls --profile sriram
```
**Approach-2**: Set the environment variable AWS_PROFILE. For example:
```
$ env | grep AWS
AWS_PROFILE=sriram
```

### Example of using same provider with different alias:
If `providers.tf` contains:
```
provider "aws" {
  region  = "us-east-1"
  profile = "account1"
}

provider "aws" {
  alias   = "account2"
  region  = "us-east-1"
  profile = "account2"
}
```
Then the two aws accounts/profiles can be used for creating resources in two AWS accounts like:
```
resource "aws_s3_bucket" "account1_bucket" {
  bucket   = "account1-bucket"
  provider = aws
}

resource "aws_s3_bucket" "account2_bucket" {
  bucket   = "account2-bucket"
  provider = aws.account2
}
```


## **variables.tf** / **input.tf** : 
Centralizes configurable input variable values like region, profile, resource names, etc. For example:

```
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS credentials profile"
  type        = string
  default     = "default"
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a"]
}

variable "user_information" {
  type = object({
    name    = string
    address = string
  })
  sensitive = true
}
```

These variables can be used in other block like:
```
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "some_resource" "a" {
  name    = var.user_information.name
  address = var.user_information.address
}
```

## main.tf :
Focuses on infrastructure without cluttering version and provider details. For example:
```
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"
  acl    = "private"
}
```


## outputs.tf :
Defines outputs that can be used by other modules or displayed in CLI. For example:
```
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
```



## Reusability: Using Modules
For better reusability across projects, you can create modules and call them from different environments.
You can create a module as a separate git repository remotely or just as a different local folder with `.tf` files.
For example, using a remote module and a local module where the input of one module is coming from the output of another module.

***main.tf***

```
# Module 1: VPC (Local Module)
module "vpc" {
  source = "./modules/vpc" # Path to the local module directory
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  tags = {
    Name = "example-vpc"
  }
}

# Module 2: Subnets (Remote Module)
module "subnets" {
  source = "github.com/terraform-aws-modules/terraform-aws-subnet.git" # Remote module source
  version = "v1.0.0" # Specify version
  vpc_id = module.vpc.vpc_id # Input from the output of the VPC module
  cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"] # Example CIDR blocks for subnets
  tags = {
    Name = "example-subnets"
  }
}


```

> [!TIP]  
> 




## Additional Information: Terraform versioning syntax examples:

| **Operator**  | **Example**         | **Allowed Versions** | **Not Allowed** | **Behavior** |
|--------------|-------------------|----------------------|-----------------|--------------|
| `=`          | `= 4.16.0`        | **Only** `4.16.0`   | `4.16.1`, `4.17.0`, `5.0.0` | Locks to an exact version. No upgrades allowed. |
| `>`          | `> 4.16.0`        | `4.16.1`, `4.17.0`, `5.0.0`, etc. | `4.16.0` and below | Allows only versions greater than the specified one. |
| `<`          | `< 4.16.0`        | `4.15.9`, `4.15.8`, etc. | `4.16.0` and above | Allows only versions lower than the specified one. |
| `>=`         | `>= 4.16.0`       | `4.16.0`, `4.16.1`, `4.17.0`, `5.0.0` | `4.15.x` and below | Allows any version equal to or greater than the specified one. |
| `<=`         | `<= 4.16.0`       | `4.16.0`, `4.15.9`, `3.x.x` | `4.16.1` and above | Allows any version equal to or lower than the specified one. |
| `~>` **(Recommended)**         | `~> 4.16.2`       | `4.16.2`, `4.16.3`, `4.16.99` | `4.17.0+`, `5.0.0` | Allows **only patch updates**, but prevents minor and major upgrades. |
| `>= , <`     | `>= 4.16.2, < 5.0.0` | Same as `~> 4.16.2` | Same as `~> 4.16.2` | Equivalent to `~> 4.16`, allows upgrades within `4.16.x` but **blocks `5.0.0+`**. |







## References:
- https://developer.hashicorp.com/terraform/language


