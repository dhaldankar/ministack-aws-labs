resource "aws_iam_role_policy" "read_target" {
  name = "read-target"
  role = aws_iam_role.lab.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = []
      Resource = []
    }]
  })
}
