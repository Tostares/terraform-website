# data "aws_instances" "wordpress_instance" {
#   filter {
#     name   = "tag:Name"
#     values = ["WordPress-Instance-fluff"]
#   }
#   instance_state_names = ["pending"]
# }

# data "aws_instance" "wordpress_instance" {
#   instance_id = data.aws_instances.wordpress_instance.ids[0]
# }

# Retrieve the EC2 instance details created with the EC2 configuration
data "aws_instance" "wordpress_instance" {
  instance_id = aws_instance.wordpress_instance.id
  depends_on  = [aws_instance.wordpress_instance]
}

# Create an autoscaling launch template dependent on the EC2 Instance after the creation
resource "aws_launch_template" "scaling_launch_template" {
  name_prefix            = "scaling_launch_template"
  image_id               = data.aws_instance.wordpress_instance.ami
  instance_type          = data.aws_instance.wordpress_instance.instance_type
  key_name               = data.aws_instance.wordpress_instance.key_name
  vpc_security_group_ids = data.aws_instance.wordpress_instance.vpc_security_group_ids
  #user_data              = base64encode(data.template_file.UserDataEC2.rendered)

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "WordPress Instance AS"
    }
  }

    depends_on = [aws_instance.wordpress_instance]
}

# #Create a launch template
# resource "aws_launch_template" "scaling_launch_template" {
#   name_prefix            = "scaling_launch_template"
#   image_id               = data.aws_ami.amazon_linux.id
#   instance_type          = var.ec2_instance_type
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
#   user_data              = base64encode(data.template_file.UserDataEC2.rendered)

#   lifecycle {
#     create_before_destroy = true
#   }
#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "WordPress Instance AS"
#     }
#   }
# }

# Create an autoscaling policy using the launch template for when to scale out
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale_out"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling_group.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80.0
  }
} 

# Create a launch configuration for EC2 instances to scale out
resource "aws_launch_configuration" "scaling_launch_config" {
  image_id        = data.aws_ami.amazon_linux_2.id
  instance_type   = var.ec2_instance_type
  security_groups = ["${aws_security_group.wordpress_sg.id}"]
  key_name        = var.key_name
}

# Create an autoscaling group using launch configuration
resource "aws_autoscaling_group" "wordpress_autoscaling_group" {
  #launch_configuration = aws_launch_configuration.scaling_launch_config.name
  launch_template {
    id      = aws_launch_template.scaling_launch_template.id
    version = "$Latest" #aws_launch_template.wordpress_launch_template.latest_version
  }

  name                      = "wordpress-asg"
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.public[0].id, aws_subnet.public[1].id] #var.private_subnet_cidr_blocks
  target_group_arns         = [aws_lb_target_group.Wordpress_target_group.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "Wordpress_Instance_AS${var.tagNameDate}-"
    propagate_at_launch = true
  }
}