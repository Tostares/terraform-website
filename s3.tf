provider "aws" {
   region = "us-west-2"
}

Create a S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
    bucket = "fluffyt0wn"
    acl = "private"

    tags = {
        Name = "My bucket"
        Environment = "Dev"
    }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = "fluffyt0wn"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AWSCloudTrailAclCheck",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudtrail.amazonaws.com"
        },
        "Action" : "s3:GetBucketAcl",
        "Resource" : aws_s3_bucket.wordpress.arn #"arn:aws:s3:::s3-bucket-2024-04-12-2973"
      },
      {
        "Sid" : "AWSCloudTrailWrite",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudtrail.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : aws_s3_bucket.wordpress.arn # "arn:aws:s3:::s3-bucket-2024-04-12-2973/*",
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
