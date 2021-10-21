/*
Terraform variables that should be configured from the user.
Variable 1: prefix 
--description: string text var to distinguish infrastructure from development to production resours
--values accepted: [production, development]

Variable 2: credentials path
--description: the local directory to find the AWS connection credentials
--values accepted: path

Variable 3: location
--description: availability zone of AWS instances
--values accepted: us-east-2a

Issue: For some reason .tfvars file is not recognized by terraform plan. Thus, a variables.tf should be created
*/
prefix = "development"
credentials_path = "credentials_path"
mysql_master_username = "SpanosDevMySQL"
mysql_master_password = "HaSh1CoR3!"
location = "us-east-2"
aws_access_key = "some_access_key"
aws_secret_key = "some_secret_key"