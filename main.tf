
data "external" "sshkey_wrapper" {
  program = ["${path.module}/key_wrapper.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    kms_arn   = var.kms_arn
    s3_bucket = var.s3_bucket
    s3_key    = var.s3_key
  }
}
