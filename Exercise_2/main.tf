provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "archive_file" "lambda_zip" {
    type = "zip"
    source_file = "lambda.py"
    output_path = var.lambda_output_path
}

resource "aws_iam_role" "test_role" {
  name = "test_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_func_policy" {
  name        = "lambda_func_policy"
  path        = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_role_func_policy" {
  role       = aws_iam_role.test_role.name
  policy_arn = aws_iam_policy.lambda_func_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_func_log_group" {
  name = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_name
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler = "lambda.lambda_handler"
  runtime = "python3.8"
  role = aws_iam_role.test_role.arn

 environment{
      variables = {
          dailb = "Dai Says Hello World!"
      }
  }

 depends_on = [aws_iam_role_policy_attachment.lambda_role_func_policy, aws_cloudwatch_log_group.lambda_func_log_group]
}
