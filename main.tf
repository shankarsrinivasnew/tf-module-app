resource "aws_security_group" "sgr" {
  name        = "${var.env}-${var.component}-sg"
  description = "${var.env}-${var.component}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "for ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_cidr
  }


  ingress {
    description = "for prometheus traffic"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.prometheus_cidr
  }

  ingress {
    description = "for internal application traffic"
    from_port   = var.port_internal
    to_port     = var.port_internal
    protocol    = "tcp"
    cidr_blocks = var.allow_app_to_subnet
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


  image_id = data.aws_ami.ownami.image_id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = var.instance_type

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      { Name = "${var.component}-${var.env}", Monitor = "yes" }
    )
  }

    tag_specifications {
    resource_type = "spot-instances-request"

    tags = merge(
      var.tags,
      { Name = "${var.component}-${var.env}", Monitor = "yes" }
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
  target_group_arns   = [aws_lb_target_group.tgr.arn]

  launch_template {
    id      = aws_launch_template.templater.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "tgr" {
  name                 = "${var.component}-${var.env}-tg"
  port                 = var.port_internal
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 5
    timeout             = 4
    path                = "/health"
  }
  tags = merge(
    var.tags,
    { Name = "${var.component}-${var.env}" }
  )
}

resource "aws_route53_record" "myr53" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = local.dns_name
  type    = "CNAME"
  ttl     = 30
  records = [var.alb_dns_name]
}


resource "aws_lb_listener_rule" "rule1" {
  listener_arn = var.listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgr.arn
  }

  condition {
    host_header {
      values = [local.dns_name]
    }
  }
}


resource "aws_autoscaling_policy" "asgpolicy" {
  name        = "cpu-util-tracking"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 20.0
  }
  autoscaling_group_name = aws_autoscaling_group.asgr.name
}
