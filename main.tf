terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "random_id" "rand_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "webapp_bucket" {
  bucket = "webapp-bucket-${random_id.rand_id.hex}"
}

# ✅ Disable Block Public Access first
resource "aws_s3_bucket_public_access_block" "webapp_bucket_block" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# ✅ Ensure policy is applied AFTER blocking is disabled
resource "aws_s3_bucket_policy" "webapp" {
  depends_on = [aws_s3_bucket_public_access_block.webapp_bucket_block]  # <-- Important

  bucket = aws_s3_bucket.webapp_bucket.id
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid       = "PublicReadGetObject",
          Effect    = "Allow",
          Principal = "*",
          Action    = "s3:GetObject",
          Resource  = "${aws_s3_bucket.webapp_bucket.arn}/*"
        }
      ]
    }
  )
}

# ✅ Upload your static website files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.webapp_bucket.bucket
  source       = "./index.html"
  key          = "index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.webapp_bucket.bucket
  source       = "./styles.css"
  key          = "styles.css"
  content_type = "text/css"
}

# ✅ Output the random ID used in bucket name
output "name" {
  value = random_id.rand_id.hex
}
