locals {
  kms_arn   = try(var.setup["kms_arn"], var.kms_arn)
  s3_bucket = try(var.setup["s3_bucket"], var.s3_bucket)
  s3_key    = try(var.setup["s3_key"], var.s3_key)
}

data "external" "sshkey_wrapper" {
  program = ["bash", abspath("${path.module}/key_wrapper.sh")]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    kms_arn   = local.kms_arn
    s3_bucket = local.s3_bucket
    s3_key    = local.s3_key
  }
}
