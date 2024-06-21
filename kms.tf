resource "aws_kms_key" "root" {
  description             = "Boundary root key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.cluster_name}-boundary-root-key"
  }
}

resource "aws_kms_key" "recovery" {
  description             = "Boundary recovery key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.cluster_name}-boundary-recovery-key"
  }
}

resource "aws_kms_key" "worker-auth" {
  description             = "Boundary worker-auth key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.cluster_name}-boundary-worker-auth-key"
  }
}

resource "aws_kms_key" "bsr" {
  description             = "Boundary bsr key"
  deletion_window_in_days = 10

  tags = {
    Name = "${var.cluster_name}-boundary-bsr-key"
  }
}