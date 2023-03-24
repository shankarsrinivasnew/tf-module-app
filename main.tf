resource "aws_security_group" "sgr" {
  name        = "${var.env}-${var.component}-sg"
  description = "${var.env}-${var.component}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description      = "for ssh traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr
  }

  ingress {
    description      = "for internal application traffic"
    from_port        = var.port
    to_port          = var.port
    protocol         = "tcp"
    cidr_blocks      = var.allow_app_to
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
      var.tags,
      { Name = "${var.component}-${var.env}" }
    )
}



resource "aws_launch_template" "templater" {
  name = "${var.env}-${var.component}-template"

  /* iam_instance_profile {
    name = "test"
  } */

  image_id = data.aws_ami.ownami.image_id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      { Name = "${var.component}-${var.env}" }
    )
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    component = var.component
  }))

  vpc_security_group_ids = [aws_security_group.sgr.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }


}


resource "aws_autoscaling_group" "asgr" {
  name                = "${var.component}-${var.env}-asg"
  vpc_zone_identifier = var.subnets
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  launch_template {
    id      = aws_launch_template.templater.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = false
  }



}
