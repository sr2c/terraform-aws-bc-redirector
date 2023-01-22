locals {
  sqlalchemy_database_uri = "postgresql://webapp:${random_password.db_password.result}@${module.rds_instance.instance_endpoint}/webapp"
}

module "conf_log" {
  source                       = "sr2c/ec2-conf-log/aws"
  version                      = "0.0.2"
  context                      = module.this.context
  disable_configuration_bucket = true
  disable_logs_bucket          = true
}

resource "aws_security_group" "allow_db_access" {
  name        = "${module.this.id}-db-access"
  description = "Allow access to the database"
  vpc_id      = data.aws_vpc.default.id
}

module "instance" {
  source                      = "cloudposse/ec2-instance/aws"
  version                     = "0.45.1"
  attributes                  = ["instance"]
  ami                         = "ami-0cbea92f2377277a4"
  ami_owner                   = data.aws_ami.ubuntu.owner_id
  instance_type               = "t3.medium"
  vpc_id                      = data.aws_vpc.default.id
  security_groups             = [aws_security_group.allow_db_access.id]
  subnet                      = data.aws_subnet.first.id
  context                     = module.this.context
  instance_profile            = module.conf_log.instance_profile_name
  associate_public_ip_address = true
  security_group_rules = [

    {
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "description" : "Allow all outbound traffic",
      "from_port" : 0,
      "protocol" : "-1",
      "to_port" : 65535,
      "type" : "egress"
    },
    {
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "description" : "Allow access to SSH",
      "from_port" : 22,
      "protocol" : "6",
      "to_port" : 22,
      "type" : "ingress"
    },
    {
      "cidr_blocks" : [
        "0.0.0.0/0"
      ],
      "description" : "Allow access to HTTP",
      "from_port" : 5000,
      "protocol" : "6",
      "to_port" : 5000,
      "type" : "ingress"
    }
  ]
  user_data_base64 = data.cloudinit_config.this.rendered
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "rds_instance" {
  source                      = "cloudposse/rds/aws"
  version                     = "0.40.0"
  context                     = module.this.context
  attributes                  = ["rds"]
  security_group_ids          = [aws_security_group.allow_db_access.id]
  database_name               = "webapp"
  database_user               = "webapp"
  database_password           = random_password.db_password.result
  database_port               = 5432
  storage_type                = "gp2"
  allocated_storage           = 10
  storage_encrypted           = true
  engine                      = "postgres"
  engine_version              = "14.5"
  major_engine_version        = "14"
  instance_class              = "db.t3.micro"
  db_parameter_group          = "postgres14"
  publicly_accessible         = false
  subnet_ids                  = [data.aws_subnet.first.id, data.aws_subnet.second.id]
  vpc_id                      = data.aws_vpc.default.id
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = false
  maintenance_window          = "Mon:03:00-Mon:04:00"
  skip_final_snapshot         = false
  copy_tags_to_snapshot       = true
  backup_retention_period     = 7
  backup_window               = "22:00-03:00"
}

module "entry_point" {
  providers = {
    aws     = aws,
    aws.acm = aws.acm
  }
  for_each       = toset(var.entry_points)
  source         = "./modules/entry-point"
  context        = module.this.context
  attributes     = [replace(each.value, ".", "-")]
  domain_name    = each.value
  ec2_public_dns = module.instance.public_dns
}
