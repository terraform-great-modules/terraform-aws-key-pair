
variable "kms_arn" {
  default     = ""
  type        = string
  description = "KMS arn for password hiding"
}

variable "s3_bucket" {
  default     = ""
  type        = string
  description = "Bucket where to store the key"
}

variable "s3_key" {
  default     = ""
  type        = string
  description = "Key path where to find/upload the key on the given bucket"
}

variable "setup" {
  default = null
  type = object({
    kms_arn   = string
    s3_bucket = string
    s3_key    = string
  })
  description = "A map containing all of the above"
}
