
output "keypath" {
  value = data.external.sshkey_wrapper.result.keypath
}

output "pub" {
  value = data.external.sshkey_wrapper.result.pub
}
