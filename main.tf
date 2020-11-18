provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "boundary" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.boundary_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  count                       = var.num_boundary

  availability_zone = data.terraform_remote_state.vpc.outputs.aws_azs[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]
  subnet_id         = data.terraform_remote_state.vpc.outputs.aws_public_subnets[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]

  tags = {
    Name  = "${var.cluster_name}-boundary-${count.index}"
    Owner = var.owner
    # Keep = ""
    boundary = var.cluster_name
  }
}

resource "null_resource" "ansible" {
  count = var.num_boundary

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/${var.instance_username}/ansible",
      "sudo yum -y install epel-release",
      "sudo yum -y install ansible",
    ]
  }

  provisioner "file" {
    source      = "./ansible/"
    destination = "/home/${var.instance_username}/ansible/"
  }

  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'ADDR=${element(aws_instance.boundary.*.private_ip, count.index)} NODE_NAME=boundary-s${count.index} BOUNDARY_VERSION=${var.boundary_version}' boundary-controller.yml",
    ]
  }

  connection {
    host        = coalesce(element(aws_instance.boundary.*.public_ip, count.index), element(aws_instance.boundary.*.private_ip, count.index))
    type        = "ssh"
    user        = var.instance_username
    private_key = var.private_key
  }

  triggers = {
    always_run = timestamp()
  }
}

resource "aws_instance" "test" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.test_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = false
  count                       = var.num_test

  availability_zone = data.terraform_remote_state.vpc.outputs.aws_azs[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]
  subnet_id         = data.terraform_remote_state.vpc.outputs.aws_private_subnets[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]

  tags = {
    Name  = "${var.cluster_name}-test-${count.index}"
    Owner = var.owner
    # Keep = ""
    boundary = var.cluster_name
  }
}