
variable "kms_arn" {
  description = "KMS arn for password hiding"
}

variable "s3_bucket" {
  description = "Bucket where to store the key"
}

variable "s3_key" {
  description = "Key path where to find/upload the key on the given bucket"
}
