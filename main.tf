resource "aws_launch_template" "templater" {
  name_prefix   = "${var.env}-${var.name}-template"
  image_id      = data.aws_ami.ownami.image_id
  instance_type = var.instance_type
}

resource "aws_autoscaling_group" "asgr" {
  availability_zones = var.availability_zones
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size

  launch_template {
    id      = aws_launch_template.templater.id
    version = "$Latest"
  }
}