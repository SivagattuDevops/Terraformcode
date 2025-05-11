/*

resource "aws_s3_bucket" "mys3gattu" {
  bucket = "bucketqueenchef"
  versioning {
      enabled = true
  }


tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
  }


resource "aws_s3_bucket_acl" "bucket_acl" {
    bucket = aws_s3_bucket.mys3gattu.id
    acl    = "public-read"
  }


  resource "aws_s3_bucket_public_access_block" "pem_access" {
    bucket = aws_s3_bucket.mys3gattu.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false

  }

resource "aws_s3_bucket_policy" "mys3gattu" {
  bucket = aws_s3_bucket.mys3gattu.id
  policy = data.aws_iam_policy_document.allow_read_only_access.json
}


data "aws_iam_policy_document" "allow_read_only_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::563024908183:user/Doraemon"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.mys3gattu.arn,
      "${aws_s3_bucket.mys3gattu.arn}/*",
    ]
  }
}
resource "aws_s3_bucket" "mygattuversion" {
    bucket = "bucketqueenchefversion"
    versioning {
      enabled = true
    }
  }

*/


  # Random suffix to ensure globally unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# 🔹 Destination bucket in eu-west-1
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

resource "aws_s3_bucket" "mycrrnikithabucket" {
  provider = aws.eu
  bucket   = "nikithagattu97"

  versioning {
    enabled = true
  }
}

# 🔹 Source bucket in us-east-1
provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

resource "aws_s3_bucket" "mycrrgattubucket" {
  provider = aws.us
  bucket   = "gattusiva93"

  versioning {
    enabled = true
  }
}

# 🔹 IAM Role for replication
resource "aws_iam_role" "replication_role" {
  name = "s3-crr-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "s3-crr-replication-policy"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.mycrrgattubucket.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = [
          "${aws_s3_bucket.mycrrgattubucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        Resource = [
          "${aws_s3_bucket.mycrrnikithabucket.arn}/*"
        ]
      }
    ]
  })
}

# 🔹 Replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.us
  bucket   = aws_s3_bucket.mycrrgattubucket.id
  role     = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-everything"
    status = "Enabled"

    filter {}

delete_marker_replication {
  status = "Disabled"
}

    destination {
      bucket        = aws_s3_bucket.mycrrnikithabucket.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.mycrrgattubucket,
    aws_s3_bucket_versioning.mycrrnikithabucket
  ]
}

# Optional: separate versioning blocks if needed
resource "aws_s3_bucket_versioning" "mycrrgattubucket" {
  bucket = aws_s3_bucket.mycrrgattubucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "mycrrnikithabucket" {
  provider = aws.eu
  bucket   = aws_s3_bucket.mycrrnikithabucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
