resource "null_resource" "launch" {
  depends_on = [null_resource.install_docker_with_ansible, local_file.compose]

  provisioner "file" {
    source      = local_file.compose.filename
    destination = "/root/docker-compose.yaml"
    connection {
      type        = "ssh"
      host        = vultr_instance.current.main_ip
      user        = "root"
      private_key = file("${path.module}/secrets/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "docker-compose up -d",
      "docker-compose ps"
    ]
    connection {
      type        = "ssh"
      host        = vultr_instance.current.main_ip
      user        = "root"
      private_key = file("${path.module}/secrets/id_rsa")
    }
  }
}