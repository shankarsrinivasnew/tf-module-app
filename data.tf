data "aws_ami" "ownami" {
  most_recent = true
  name_regex  = "devops-practice-with-ansible"
  owners      = ["self"]
}
