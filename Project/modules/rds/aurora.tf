resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0

  name   = "${var.identifier}-cluster-pg"
  family = var.aurora_parameter_group_family

  parameter {
    name  = "log_statement"
    value = var.log_statement
  }

  parameter {
    name  = "work_mem"
    value = var.work_mem
  }

  tags = {
    Name = "${var.identifier}-cluster-pg"
  }
}

resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier              = var.identifier
  engine                          = var.aurora_engine
  engine_version                  = var.aurora_engine_version
  database_name                   = var.db_name
  master_username                 = var.db_username
  master_password                 = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name
  skip_final_snapshot             = true

  tags = {
    Name = var.identifier
  }
}

resource "aws_rds_cluster_instance" "writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.identifier}-writer"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  tags = {
    Name = "${var.identifier}-writer"
  }
}
