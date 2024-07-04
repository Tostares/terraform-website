locals {
  name = "WordPress Instance ${var.tagNameDate}"
}
#Get latest ami ID of Amazon Linux - values = ["al2023-ami-2023*x86_64"]
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
}

resource "aws_instance" "wordpress_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ec2_instance_type
  availability_zone           = var.availability_zones[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.wordpress_sg.id]
  subnet_id                   = aws_subnet.public[0].id # Choose one of the public subnets


  tags = {
    Name = local.name
  }
  user_data = file("UserDataEC2.sh")
  #user_data = data.template_file.userdataEC.rendered

}