provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "boundary" {
  ami                         = var.amis[var.aws_region]
  instance_type               = var.boundary_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.default.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.boundary_profile.id
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
      "sudo yum -y install python3-pip",
      "sudo python3 -m pip install ansible --quiet",
    ]
  }

  provisioner "file" {
    source      = "./ansible/"
    destination = "/home/${var.instance_username}/ansible/"
  }

  provisioner "file" {
    content     = tls_locally_signed_cert.server.cert_pem
    destination = "/home/${var.instance_username}/ansible/files/boundary.crt"
  }

  provisioner "file" {
    content     = tls_private_key.server.private_key_pem
    destination = "/home/${var.instance_username}/ansible/files/boundary.key"
  }

  provisioner "file" {
    content     = tls_self_signed_cert.ca.cert_pem
    destination = "/home/${var.instance_username}/ansible/files/boundary.ca"
  }

  provisioner "remote-exec" {
    inline = [
      "cd ansible; ansible-playbook -c local -i \"localhost,\" -e 'ADDR=${element(aws_instance.boundary.*.private_ip, count.index)} NODE_NAME=boundary-c${count.index} BOUNDARY_LICENSE=${var.boundary_license} KMS_KEY_ROOT=${aws_kms_key.root.id} KMS_KEY_RECOVERY=${aws_kms_key.recovery.id} KMS_KEY_WORKER_AUTH=${aws_kms_key.worker-auth.id} KMS_KEY_BSR=${aws_kms_key.bsr.id} AWS_REGION=${var.aws_region} DATABASE_NAME=${module.rds.database_name} DATABASE_ENDPOINT=${module.rds.endpoint} DATABASE_PASSWORD=${module.rds.database_password} DATABASE_USERNAME=${var.boundary_database_username} BOUNDARY_VERSION=${var.boundary_version}' all.yml",
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

  depends_on = [module.rds]
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
    values = ["Windows_Server-2025-English-Full-Base-2025.03.12"]
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