# Terraform configuration to create Lambda functions for EC2 Start/Stop

provider "aws" {
  region = "us-east-1"
}

# IAM Role for Lambda with EC2 permissions
resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda_ec2_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" },
      Effect    = "Allow",
      Sid       = ""
    }]
  })
}

# IAM Policy to allow EC2 actions
resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_permissions"
  role = aws_iam_role.lambda_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Archive the Lambda function code (manually place ec2_start.py and ec2_stop.py in ./lambda folder)
data "archive_file" "ec2_start_zip" {
  type        = "zip"
  source_file = "./modules/lambda/lambda/ec2_start.py"
  output_path = "./modules/lambda/lambda/ec2_start.zip"
}

data "archive_file" "ec2_stop_zip" {
  type        = "zip"
  source_file = "./modules/lambda/lambda/ec2_stop.py"
  output_path = "./modules/lambda/lambda/ec2_stop.zip"
}

# Lambda function to start EC2 instances
resource "aws_lambda_function" "ec2_start" {
  filename         = data.archive_file.ec2_start_zip.output_path
  function_name    = "Ec2_Startlambda"
  role             = aws_iam_role.lambda_ec2_role.arn
  handler          = "ec2_start.lambda_handler"
  runtime          = "python3.12"
  timeout          = 180
  source_code_hash = data.archive_file.ec2_start_zip.output_base64sha256
}

# Lambda function to stop EC2 instances
resource "aws_lambda_function" "ec2_stop" {
  filename         = data.archive_file.ec2_stop_zip.output_path
  function_name    = "Ec2_Stoplambda"
  role             = aws_iam_role.lambda_ec2_role.arn
  handler          = "ec2_stop.lambda_handler"
  runtime          = "python3.12"
  timeout          = 180
  source_code_hash = data.archive_file.ec2_stop_zip.output_base64sha256
}

# CloudWatch Event rule to trigger EC2 Stop at 12 AM daily
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "ec2_stop_schedule"
  schedule_expression = "cron(0/3 * * * ? *)"
}

# CloudWatch Event rule to trigger EC2 Start at 6 AM daily
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "ec2_start_schedule"
  schedule_expression = "cron(0/3 * * * ? *)"
}

# Event targets to link schedule with Lambda
resource "aws_cloudwatch_event_target" "start_lambda_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "StartEC2"
  arn       = aws_lambda_function.ec2_start.arn
}

resource "aws_cloudwatch_event_target" "stop_lambda_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "StopEC2"
  arn       = aws_lambda_function.ec2_stop.arn
}

# Grant CloudWatch Events permission to invoke Lambda
resource "aws_lambda_permission" "allow_start_invocation" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}

resource "aws_lambda_permission" "allow_stop_invocation" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}



# SNS Topic
resource "aws_sns_topic" "start_instance_alert" {
  name = "StartInstanceNotificationTopic"
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "email"
  endpoint  = "sivagattu97@gmail.com"
}

# SNS SMS Subscription
resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "sms"
  endpoint  = "8341103848"
}


# SNS Topic as Lambda Destination (invoke manually or via some trigger)
resource "aws_lambda_permission" "sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_start.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_instance_alert.arn
}

resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ec2_start.function_name
}
