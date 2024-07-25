#creating DB Subnet Group
resource "aws_db_subnet_group" "private" {
  name       = "private_group"
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]

  tags = {
    Name = "Private_Group ${var.tagNameDate}"
  }
}

#Creating MySQL RDS database
resource "aws_db_instance" "mysql" {
  allocated_storage      = "10"
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  identifier             = "rds-db"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  multi_az               = false
  storage_encrypted      = false
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private.name #Associate private subnet to db instance

  tags = {
    Name = "rds_db ${var.tagNameDate}"
  }
}

data "aws_db_instance" "mysql_data" {
  db_instance_identifier = aws_db_instance.mysql.identifier
}

#Get Database name, username, password, endpoint from above RDS
output "db_name" {
  value = data.aws_db_instance.mysql_data.db_name
}
output "db_username" {
  value = var.db_username
}
output "db_password" {
  value     = var.db_password
  sensitive = true
}
output "RDS_endpoint" {
  value = data.aws_db_instance.mysql_data.endpoint
}

