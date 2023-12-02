provider "aws" {
  region = "eu-central-1"
}


# Create an ECR repository for MySQL
resource "aws_ecr_repository" "mysql" {
  name = "mysql_repository"
}

# Create an ECR repository for Nginx
resource "aws_ecr_repository" "nginx" {
  name = "nginx_repository"
}



# Attach an IAM policy to allow everyone to pull from the MySQL repository
resource "aws_ecr_repository_policy" "mysql_policy" {
  repository = aws_ecr_repository.mysql.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
      },
    ],
  })
}

# Attach an IAM policy to allow everyone to pull from the Nginx repository
resource "aws_ecr_repository_policy" "nginx_policy" {
  repository = aws_ecr_repository.nginx.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
      },
    ],
  })
}
