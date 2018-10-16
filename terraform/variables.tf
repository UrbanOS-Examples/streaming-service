variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "role_arn" {
  description = "The ARN for the assumed role into the environment to be changes (e.g. dev, test, prod)"
}