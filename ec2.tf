locals {
  name = "WordPress Instance ${var.tagNameDate}"
}
#Get latest ami ID of Amazon Linux - values = ["amzn2-ami-hvm-x86_64-gp2"]
data "aws_ami" "amazon_linux_2" {
    most_recent = true
   filter {
     name   = "name"
     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
   }
 }



resource "aws_instance" "wordpress_instance" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.ec2_instance_type
  availability_zone           = var.availability_zones[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.wordpress_sg.id]
  subnet_id                   = aws_subnet.public[0].id # Choose one of the public subnets


  tags = {
    Name = local.name
  }
  #user_data = file("UserDataEC2.sh")
  #set up with userdata template to collect variables
  user_data = templatefile("${path.module}/UserDataEC2.sh", 
    {
      #make sure your variables are the same as your userdata.tpl
      db_name     = var.db_name
      db_username = var.db_username
      db_password = var.db_password
      db_endpoint = aws_db_instance.mysql.endpoint 
    })  
}

output "PublicIP" {
  value = aws_instance.wordpress_instance.public_ip
}
  
  
  
  
  #user_data = data.template_file.userdataEC.rendered

#}

# data "template_file" "userdataEC" {
#   template = file("UserDataEC2.sh")

#   vars = {
#     rds_endpoint = replace("${data.aws_db_instance.mysql_data.endpoint}", ":3306", "")
#     db_username = "${var.db_username}"
#     db_password = "${var.db_password}"
#     db_name  = "${data.aws_db_instance.mysql_data.db_name}"
#   }
# }