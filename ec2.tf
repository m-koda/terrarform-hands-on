resource "aws_instance" "example" {
  ami                    = data.aws_ami.amazon-linux-2.image_id
  vpc_security_group_ids = [aws_security_group.terraform-hands-on.id]
  subnet_id              = aws_subnet.public-a.id
  key_name               = "terraform-hands-on"
  instance_type          = "t2.micro"

  tags = {
    Name = "terraform-hands-on"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}