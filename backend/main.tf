module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "jrand-terraform-backend"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  
  lifecycle_rule = [
    {
      id                                     = "noncurrent-expiration"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_expiration = {
        days = 90
      }
    },
  ]
}
