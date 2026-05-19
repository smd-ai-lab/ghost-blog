resource "null_resource" "launch" {
  depends_on = [null_resource.install_docker_with_ansible, local_file.compose]

  provisioner "file" {
    source      = "${path.module}/conf/nginx.conf"
    destination = "/root/nginx.conf"
    connection {
      type        = "ssh"
      host        = vultr_instance.current.main_ip
      user        = "root"
      private_key = file("${path.module}/secrets/id_rsa")
    }
  }
}