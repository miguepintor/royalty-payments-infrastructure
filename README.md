# royalty-payments-infrastructure
Terraform templates to build the infrastructure for the royalty-payments system.

# HOW TOs
## Prerequisites
To set up the project you need first to install: [terraform](https://www.terraform.io/downloads.html).

This project uses the default AWS credentials (linked to an AWS account) of your AWS cli tool.
If you dont have it installed follow this guide: https://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-chap-install.html
After that configure it properly following this guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html

## Bulding the infrastructure
Follow this steps:
1. Initialize the project by executing:
```bash
terraform init
```
2. Run the infrastructre (review carefully all the resources that will be created):
```bash
terraform apply
```
## Destroying the infrastructure
Just execute this:
```bash
terraform destroy
```