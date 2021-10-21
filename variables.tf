variable "location" {
	description = "Resource allocation zone in AWS"
  default     = "us-east-2"
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
