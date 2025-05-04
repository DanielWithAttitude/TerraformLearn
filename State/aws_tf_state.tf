terraform {
   #backend "s3" {
   #  bucket         = "terraform-learn-tf-state-daniel" 
   #  key            = "03-basics/import-bootstrap/terraform.tfstate"
   #  region         = "eu-north-1"
   #  dynamodb_table = "terraform-state-locking"
   #  encrypt        = true
   #}
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-learn-tf-state-daniel"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket        = aws_s3_bucket.terraform_state.bucket 
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket_policy" "alb_log_policy" {
  bucket = aws_s3_bucket.terraform_state.bucket

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.terraform_state.bucket}/webserver-lb-access-log/AWSLogs/831645032308/*"
    }
  ]
})
}