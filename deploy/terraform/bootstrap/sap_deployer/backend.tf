/*
Description:

  To use remote backend to deploy deployer(s).
*/
terraform {
  backend "local" {
    path = "./deployer.terraform.tfstate"
  }
}
