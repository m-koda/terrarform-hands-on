resource "aws_security_group" "terraform-hands-on" {
  vpc_id = aws_vpc.main.id
  name   = "terraform-hands-on"

  tags = {
    Name = "terraform-hands-on"
  }
}

resource "aws_security_group_rule" "in_ssh" {
  security_group_id = aws_security_group.terraform-hands-on.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.terraform-hands-on.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}