module "rds" {
  source                 = "app.terraform.io/jrxhc/rds/aws"
  version                = "0.0.1"
  cluster_name           = var.cluster_name
  tfe_database_name      = var.boundary_database_name
  tfe_database_username  = var.boundary_database_username
  subnet_ids             = data.terraform_remote_state.vpc.outputs.aws_public_subnets
  vpc_security_group_ids = [aws_security_group.default.id]
}