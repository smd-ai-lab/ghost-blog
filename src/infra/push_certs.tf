resource "null_resource" "push_tls_certs" {
  triggers = {
    domain_cert_hash = filesha256("${path.module}/secrets/domain.cert.pem")
    private_key_hash = filesha256("${path.module}/secrets/private.key.pem")
  }

  provisioner "file" {
    source      = "${path.module}/secrets/domain.cert.pem"
    destination = "/root/domain.cert.pem"
    connection {
      type        = "ssh"
      host        = vultr_instance.current.main_ip
      user        = "root"
      private_key = file("${path.module}/secrets/id_rsa")
    }
  }

  provisioner "file" {
    source      = "${path.module}/secrets/private.key.pem"
    destination = "/root/private.key.pem"
    connection {
      type        = "ssh"
      host        = vultr_instance.current.main_ip
      user        = "root"
      private_key = file("${path.module}/secrets/id_rsa")
    }
  }
}