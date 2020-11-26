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

resource "aws_instance" "linux" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.linux_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = false
  count                       = var.num_linux

  availability_zone = data.terraform_remote_state.vpc.outputs.aws_azs[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]
  subnet_id         = data.terraform_remote_state.vpc.outputs.aws_private_subnets[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]

  tags = {
    Name  = "${var.cluster_name}-linux-${count.index}"
    Owner = var.owner
    # Keep = ""
    boundary = var.cluster_name
  }
}

data "aws_ami" "windows-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-2020.08.12"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "win" {
  ami                         = data.aws_ami.windows-ami.image_id
  instance_type               = var.win_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = false
  count                       = var.num_win

  availability_zone = data.terraform_remote_state.vpc.outputs.aws_azs[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]
  subnet_id         = data.terraform_remote_state.vpc.outputs.aws_private_subnets[count.index % length(data.terraform_remote_state.vpc.outputs.aws_azs)]

  user_data = <<EOF
<powershell>
net user ${var.win_instance_username} '${var.win_instance_password}' /add /y
net localgroup administrators ${var.win_instance_username} /add
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 3389" protocol=TCP dir=in localport=3389 action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
EOF

  tags = {
    Name  = "${var.cluster_name}-win-${count.index}"
    Owner = var.owner
    # Keep = ""
    boundary = var.cluster_name
  }

}