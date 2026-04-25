resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1

  name   = "${var.identifier}-pg"
  family = var.db_parameter_group_family

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  parameter {
    name  = "log_statement"
    value = var.log_statement
  }

  parameter {
    name  = "work_mem"
    value = var.work_mem
  }

  tags = {
    Name = "${var.identifier}-pg"
  }
}

resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  identifier             = var.identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main[0].name
  multi_az               = var.multi_az
  skip_final_snapshot    = true

  tags = {
    Name = var.identifier
  }
}
