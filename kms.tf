# KMS key for encrypting S3 buckets (optional, can be expanded for other uses)
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/kjc-es-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}