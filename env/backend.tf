terraform {
  backend "s3" {
    bucket       = "mentoring-state-bucket"
    key          = "terraformtask2/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
