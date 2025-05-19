
# SNS Topic
resource "aws_sns_topic" "start_instance_alert" {
  name = "StartInstanceNotificationTopic"
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# SNS SMS Subscription
resource "aws_sns_topic_subscription" "sms" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "sms"
  endpoint  = var.phone_number
}


# SNS Topic as Lambda Destination (invoke manually or via some trigger)
resource "aws_lambda_permission" "sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_instance.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.start_instance_alert.arn
}

resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn = aws_sns_topic.start_instance_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.start_instance.arn
}
