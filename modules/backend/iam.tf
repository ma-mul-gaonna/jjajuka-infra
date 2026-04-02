# -- IAM Role
resource "aws_iam_role" "ec2_ssm" {
  name = "${local.prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.tags, { Name = "${local.prefix}-ec2-ssm-role" })
}

# -- Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -- Instance Profile
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${local.prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}
