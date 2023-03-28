resource "aws_iam_policy" "ssm_policy" {
  name        = "${var.component}-${var.env}-policy"
  path        = "/"
  description = "${var.component}-${var.env}-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          #"arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.env}.${var.component}*",
          #"arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.env}.docdb*",
          #"arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.env}.redis*"
          for i in local.ssm_parameters : "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.env}.${i}*"
        ]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.component}-${var.env}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    { Name = "${var.component}-${var.env}" }
  )
}

resource "aws_iam_role_policy_attachment" "ssm-attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.component}-${var.env}-profile"
  role = aws_iam_role.ssm_role.name
}