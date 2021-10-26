variable "location" {
	description = "Resource allocation zone in AWS"
  default     = "eu-west-3" #Ohio: us-east-2, Paris: eu-west-3
  type        = string
}

variable "prefix" {
  description = "Resource group prefix (i.e development/ production)"
  type        = string
}

variable "aws_access_key" {
  description = "AWS login access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS login secret key"
  type        = string
  sensitive   = true
}
