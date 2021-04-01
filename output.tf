
output "keypath" {
  value = data.external.sshkey_wrapper.result.keypath
}

output "pub" {
  value = data.external.sshkey_wrapper.result.pub
}

output "setup" {
  value = {
    kms_arn   = local.kms_arn
    s3_bucket = local.s3_bucket
    s3_key    = local.s3_key
  }
}
