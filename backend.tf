terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"
    key     = "envs/dev/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}