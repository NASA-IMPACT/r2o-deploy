data "aws_subnets" "public_subnets_id" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnets_tagname]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

}
