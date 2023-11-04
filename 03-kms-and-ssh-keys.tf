# Creating symmetric KMS Key
resource "yandex_kms_symmetric_key" "kc-key" {
  name              = "${var.kms_key_name}"
  description       = "description for key"
  default_algorithm = "AES_256"
}

# SA role binding for KMS Key described in service-account.tf
resource "yandex_kms_symmetric_key_iam_binding" "encrypterDecrypter" {
  symmetric_key_id = yandex_kms_symmetric_key.kc-key.id
  role             = "kms.keys.encrypterDecrypter"

  members = [
    "serviceAccount:${yandex_iam_service_account.kc-sa.id}",
  ]
}

#Create ssh key for guest OS
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "pt_key.pem"
  file_permission = "0600"
}
