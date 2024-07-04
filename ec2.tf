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