data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "first" {
  availability_zone = data.aws_availability_zones.available.names[0]
  default_for_az    = true
}

data "aws_subnet" "second" {
  availability_zone = data.aws_availability_zones.available.names[1]
  default_for_az    = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "cloudinit_config" "this" {
  base64_encode = true
  gzip          = true

  part {
    content = templatefile("${path.module}/templates/user_data.yaml", {
      start_script = jsonencode(file("${path.module}/templates/start.sh")),
      crontab      = jsonencode(file("${path.module}/templates/cron")),
      app_config = jsonencode(yamlencode({
        SQLALCHEMY_DATABASE_URI : local.sqlalchemy_database_uri,
        DEFAULT_REDIRECTOR_DOMAIN : var.default_redirector_domain,
        UPDATE_KEY : var.update_key,
        SECRET_KEY : var.secret_key,
        PUBLIC_KEY : var.public_key,
        UTM_MEDIUM : var.utm_medium,
        UTM_CAMPAIGN : var.utm_campaign,
        UTM_SOURCE : var.utm_source
      })) # This is a JSON string containing YAML
    })
    content_type = "text/cloud-config"
    filename     = "user_data.yaml"
  }
}
