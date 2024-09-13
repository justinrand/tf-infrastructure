data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["Gateway"]
  }
}

data "aws_subnet" "gateway" {
  filter {
    name   = "tag:Name"
    values = ["gateway-a"]
  }
}

resource "aws_security_group" "zk" {
  name        = "zookeeper"
  vpc_id      = data.aws_vpc.this.id
  description = "zookeeper comms"

  ingress = [
    {
      description      = "zk quorum port"
      from_port        = 2888
      to_port          = 2888
      protocol         = "tcp"
      cidr_blocks      = [data.aws_vpc.this.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
    {
      description      = "zk leader election"
      from_port        = 3888
      to_port          = 3888
      protocol         = "tcp"
      cidr_blocks      = [data.aws_vpc.this.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
    {
      description      = "zk client"
      from_port        = 2181
      to_port          = 2181
      protocol         = "tcp"
      cidr_blocks      = [data.aws_vpc.this.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
    {
      description      = "zk client"
      from_port        = 2182
      to_port          = 2182
      protocol         = "tcp"
      cidr_blocks      = [data.aws_vpc.this.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh" {
  vpc_id      = data.aws_vpc.this.id
  name        = "ssh"
  description = "allow ssh from anywhere"

  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "ssh inbound"
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
  }]
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "default" {
  key_name   = "default"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "default_key" {
  filename        = "secrets/default/ec2-key.pem"
  content         = tls_private_key.this.private_key_openssh
  file_permission = "0600"
}

resource "aws_instance" "zk" {
  count = var.zookeeper_count

  ami               = data.aws_ssm_parameter.ami.value
  instance_type     = "t3.small"
  availability_zone = "us-east-2a"
  vpc_security_group_ids = [
    aws_security_group.zk.id,
    aws_security_group.ssh.id,
  ]
  key_name  = aws_key_pair.default.key_name
  subnet_id = data.aws_subnet.gateway.id
  user_data = templatefile("user_data.tftpl", {
    zk_interfaces = aws_network_interface.zk[*],
    client_port   = 2182,
    zk_id         = count.index + 1,
    zk_version    = var.zookeeper_version
  })
  user_data_replace_on_change = true

  tags = {
    Name = "zookeeper"
  }
}

resource "aws_network_interface" "zk" {
  count     = var.zookeeper_count
  subnet_id = data.aws_subnet.gateway.id

  security_groups = [aws_security_group.zk.id]
  description     = "zk${count.index + 1}.local"
}

resource "aws_network_interface_attachment" "zk" {
  count = var.zookeeper_count

  device_index         = 1
  instance_id          = aws_instance.zk[count.index].id
  network_interface_id = aws_network_interface.zk[count.index].id
}
