data "aws_ami" "ownami" {
  most_recent = true
  name_regex  = "devops-practice-with-ansible"
  owners      = ["self"]
}

data "aws_caller_identity" "current" {}
