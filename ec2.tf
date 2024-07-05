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
  user_data = file("UserDataEC2.sh")
  #user_data = data.template_file.userdataEC.rendered

}