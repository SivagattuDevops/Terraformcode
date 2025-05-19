

# 🔹 S3 bucket for storing CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "my-cloudtrail-logs-bucket-gattu"  # Change to a globally unique name

  tags = {
    Name        = "CloudTrail Logs Bucket"
    Environment = "Dev"
  }
}

# 🔹 CloudWatch Log Group for real-time logs
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/CloudTrailLogs/gattu"
  retention_in_days = 30
}

# 🔹 IAM Role for CloudTrail to send logs to CloudWatch
resource "aws_iam_role" "cloudtrail_role" {
  name = "CloudTrailCloudWatchRole_gattu"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 🔹 Attach CloudWatch Logs policy to the IAM role

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
      {
        Sid = "AWSCloudTrailGetAcl",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}"
      }
    ]
  })
}




# 🔹 Create the CloudTrail trail
resource "aws_cloudtrail" "my_trail" {
  name                          = "MyCloudTrail_gattu"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  
}
