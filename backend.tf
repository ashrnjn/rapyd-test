terraform {
  backend "s3" {
    bucket  = "rapyd-test-01-09-tfstate"
    key     = "envs/dev/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}