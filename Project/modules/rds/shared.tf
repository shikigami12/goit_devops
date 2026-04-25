resource "aws_db_subnet_group" "main" {
  name        = "${var.identifier}-subnet-group"
  description = "Subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.identifier}-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-sg"
  description = "Allow database access from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.identifier}-sg"
  }
}
