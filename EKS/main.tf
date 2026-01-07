resource "aws_eks_cluster" "dev_eks_cluster" {
    name   = "dev-eks-cluster"
    role_arn = aws_iam_role.dev_eks_role.role_arn
  version = "1.31"
  vpc_config {
    subnet_ids = var.subnet_ids
  }
  depends_on = [
    aws_iam_policy_attachment.dev_eks_AmazonEKSClusterPolicy,
    aws_iam_policy_attachment.dev_eks_AmazonEKSVPCResourceController,
  ]
    tags = merge(
        var.tags,
        {
            Name = "dev-eks-cluster"
        }
    )
}

resource "aws_iam_role" "dev_eks_role" {
    name = "dev-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_policy_attachment" "dev_eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.dev_eks_role.name]
}

resource "aws_iam_policy_attachment" "dev_eks_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  roles      = [aws_iam_role.dev_eks_role.name]
}
