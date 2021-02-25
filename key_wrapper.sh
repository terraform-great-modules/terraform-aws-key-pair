#!/usr/bin/env bash

# save stdout and stderr to file
# descriptors 3 and 4,
# then redirect them to "foo"
exec 3>&1 4>&2 >/tmp/key_wrapper.log 2>&1

# Exit if any of the intermediate steps fail
set -e
set -x
set -u
set -o pipefail

error_exit() {
  exec 1>&3 2>&4
  echo "$1" 1>&2
  exit 1
}

# Read from std input and assign to local variable
eval "$(jq -r '@sh "KMS_ARN=\(.kms_arn) S3_BUCKET=\(.s3_bucket) S3_KEY=\(.s3_key)"')"

if [ "${KMS_ARN}" == "null" ]; then
  KMS_ARN=''
fi

aws s3api head-bucket --bucket "${S3_BUCKET}" || error_exit "Bucket not found"

KEYPATH_ENC="$(mktemp --suffix ".enc")"
KEYPATH="$(mktemp)"
KEYPATH_PUB="${KEYPATH}.pub"

ssh_exists () {
  status=1
  set +x
  exec 5>&1 1>&3 2>&4
  error_msg="$(aws s3api head-object --bucket "${S3_BUCKET}" --key "${S3_KEY}" 2>&1)" && status=0 || :
  exec 3>&1 4>&2 >&5 2>&1
  set -x
  if [ $status -eq 0 ]; then
    return 0
  fi
  echo "${error_msg}" | grep "operation: Not Found" && return 1
  error_exit "Not possible to inspect remote bucket: ${error_msg}"
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
  chmod 600 "${KEYPATH}"
}

gen_key() {
  if [ -f "${KEYPATH}" ] ; then
    if wc -l "${KEYPATH}" ; then
      rm "${KEYPATH}"
    else
      error_exit "File ${KEYPATH} already exists"
    fi
  fi
  ssh-keygen -f "${KEYPATH}" -P '' > /dev/null
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

gen_pub() {
  ssh-keygen -y -f "${KEYPATH}" > "${KEYPATH_PUB}"
}

test -f $(which ssh-keygen) || error_exit "ssh-keygen command not detected in path, please install it"
test -f $(which jq) || error_exit "jq command not detected in path, please install it"
if ! ssh_exists ; then
  gen_key
else
  get_key
fi
gen_pub

PUB=$(< "${KEYPATH_PUB}")


# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg keypath "${KEYPATH}" --arg pub "${PUB}" '{"keypath":$keypath, "pub":$pub}'
set +x
exec 1>&3 2>&4
jq -n --arg keypath "${KEYPATH}" --arg pub "${PUB}" '{"keypath":$keypath, "pub":$pub}'
