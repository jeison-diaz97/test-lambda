terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "us-west-2"
    profile = "my-terraform"
}

provider "aws" {
    alias = "SE-TESTING"
    region = "us-west-2"
    profile = "se-testing-terraform-jd"
}

provider "aws" {
    alias = "SE-DEVELOP"
    region = "us-west-2"
    profile = "se-development-terraform-jd"
}

provider "aws" {
    alias = "SE-PROD"
    region = "us-west-2"
    profile = "se-prod-terraform-jd"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.js"
  output_path = "lambda_function_payload.zip"
}
