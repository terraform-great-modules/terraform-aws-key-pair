#!/usr/bin/env bash

# Exit if any of the intermediate steps fail
set -e

# Read from std input and assign to local variable
eval "$(jq -r '@sh "KMS_ARN=\(.kms_arn) S3_BUCKET=\(.s3_bucket) S3_KEY=\(.s3_key)"')"

KEYPATH_ENC="$(mktemp --suffix "enc")"
KEYPATH="$(mktemp)"

ssh_exists () {
  aws s3api head-object --bucket "${S3_BUCKET}" --key "${S3_KEY}" > /dev/null && return 0 || return 1
}

get_key() {
  aws s3 cp "s3://${S3_BUCKET}/${S3_KEY}" "${KEYPATH_ENC}" > /dev/null 
  if [ -n "${KMS_ARN}" ] ; then
    aws kms decrypt \
        --key-id "${KMS_ARN}" \
        --ciphertext-blob "fileb://${KEYPATH_ENC}" \
	--output text --query Plaintext | base64 --decode > "${KEYPATH}"
  else
    mv "${KEYPATH_ENC}" "${KEYPATH}"
  fi
}

gen_key() {
  ssh-keygen -f "${KEYPATH}" > /dev/null 
  if [ -n "${KMS_ARN}" ] ; then
    aws kms encrypt \
        --key-id "${KMS_ARN}" \
        --plaintext "fileb://${KEYPATH}" \
        --output text --query CiphertextBlob | base64 --decode > "${KEYPATH_ENC}"
  else
    KEYPATH_ENC="${KEYPATH}"
  fi
  aws s3 cp "${KEYPATH_ENC}" "s3://${S3_BUCKET}/${S3_KEY}" > /dev/null 
}

if ! ssh_exists ; then
  gen_key
else
  get_key
fi


# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg keypath "$KEYPATH" '{"keypath":$keypath}'
