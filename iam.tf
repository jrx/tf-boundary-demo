data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# boundary

resource "aws_iam_role" "boundary_kms_unseal_role" {
  name               = "${var.cluster_name}-boundary-kms-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "boundary_profile" {
  name = "${var.cluster_name}-boundary_profile"
  role = aws_iam_role.boundary_kms_unseal_role.name
}

# Auto-unseal

data "aws_iam_policy_document" "boundary-kms-unseal" {
  statement {
    sid       = "BoundaryKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "ec2:DescribeInstances",
    ]
  }
}

resource "aws_iam_policy" "boundary-policy-kms-unseal" {
  name   = "${var.cluster_name}-boundary-policy-kms-unseal"
  policy = data.aws_iam_policy_document.boundary-kms-unseal.json
}

resource "aws_iam_policy_attachment" "boundary-attach-kms" {
  name       = "${var.cluster_name}-boundary-attach-kms"
  roles      = [aws_iam_role.boundary_kms_unseal_role.id]
  policy_arn = aws_iam_policy.boundary-policy-kms-unseal.arn
}