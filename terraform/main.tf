provider "aws" {
  region = "${var.region}"

  assume_role {
    role_arn = "${var.role_arn}"
  }
}

terraform {
  backend "s3" {
    key     = "streaming-service"
    encrypt = true
  }
}

resource "aws_efs_file_system" "kafka" {
  creation_token = "${terraform.workspace}-kafka"
  performance_mode = "generalPurpose" # or maxIO
  encrypted = true

  tags {
    Name = "EFS-Kafka"
    Environment = "${terraform.workspace}"
  }

  lifecycle {
    prevent_destroy = "true"
  }
}