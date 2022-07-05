variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner_id" {
  type = list(string)
  default = ["679593333241"]
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "app" {
  ami_name      = "lodgercontrol-ec2-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu-minimal/images-testing/hvm-ssd/ubuntu-jammy-daily-amd64-minimal-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = var.owner_id
  }
  ssh_username = "ubuntu"
  temporary_key_pair_type = "ed25519"
}

build {
  sources = ["source.amazon-ebs.app"]

  provisioner "shell" {
    environment_vars = [
    "USERNAME=${var.docker_username}",
    "PASSWORD=${var.docker_password}"
  ]
    script = "./setup.sh"
  }
  provisioner "file" {
    source      = "./daemon.json"
    destination = "/tmp/daemon.json"
  }
  provisioner "shell" {
    script = "./move-daemon.sh"
  }
}