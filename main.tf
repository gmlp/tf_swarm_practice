data "aws_ami" "docker"{
  filter {
    name   = "name"
    values = ["ami-ubuntu-docker-rextay-2"]
  }

  owners = ["self"]
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "terraform-states-syseng"
    key    = "fp/vpc/terraform.tfstate"
    region = "us-west-1"
  }

}


resource "aws_instance" "swarm-manager" {
  ami = "${data.aws_ami.docker.id}"
  instance_type = "${var.swarm_instance_type}"
  iam_instance_profile="rexray"
  tags {
    Name = "VM-Swarm_Manager-${var.softtek_is}"
    LabName = "${var.labName}"
  }
  vpc_security_group_ids = [
    "${data.terraform_remote_state.vpc.docker_sg_id}"
  ]
  key_name = "${var.key_name}"
  connection {
    user = "ubuntu"
    private_key = "${file("${var.private_key}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${self.private_ip}",
      "echo master | sudo tee /etc/hostname",
      "sudo hostname master",
    ]
  }
}

resource "aws_instance" "swarm-worker" {
  count = "${var.swarm_workers}"
  ami = "${data.aws_ami.docker.id}"
  instance_type = "${var.swarm_instance_type}"
  iam_instance_profile="rexray"
  tags {
    Name = "VM-Swarm_worker-${var.softtek_is}"
    LabName = "${var.labName}"
  }
  vpc_security_group_ids = [
    "${data.terraform_remote_state.vpc.docker_sg_id}"
  ]
  key_name = "${var.key_name}"
  connection {
    user = "ubuntu"
    private_key = "${file("${var.private_key}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "export TOKEN=$$(DOCKER_HOST=${aws_instance.swarm-manager.private_ip} docker swarm join-token -q worker)",
      "docker swarm join --token $$TOKEN --advertise-addr ${self.private_ip} ${aws_instance.swarm-manager.private_ip}:2377",
      "echo node | sudo tee /etc/hostname",
      "sudo hostname node${count.index}",
      "sudo sysctl -w vm.max_map_count=262144"
    ]
  }
}

output "swarm_manager_public_ip" {
  value = "${aws_instance.swarm-manager.public_ip}"
}

output "swarm_manager_private_ip" {
  value = "${aws_instance.swarm-manager.private_ip}"
}
