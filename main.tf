variable "server_port" {  
  description = "The port the server will use for HTTP requests"  
  default = 27017
}

provider "aws" {  
  region = "us-west-1"
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "instance" {  
  name = "terraform-example-instance"  
  ingress {    
    from_port = "${var.server_port}"    
    to_port = "${var.server_port}"    
    protocol = "tcp"    
    cidr_blocks = ["0.0.0.0/0"]  
  }

  ingress {    
    from_port = "22"    
    to_port = "22"    
    protocol = "tcp"    
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }


}

resource "aws_instance" "example" {  
  ami = "ami-b73d6cd7"  
  instance_type = "t2.micro"
  key_name = "tgkey1"

  vpc_security_group_ids = ["${aws_security_group.instance.id}"]  

  connection {
    user = "ec2-user"
    private_key = "${file("/home/tom/.ssh/tgkey1.pem")}"
  }

  provisioner "file" {
    source="templates/mongodb-org-3.4.repo"
    destination="/tmp/mongodb-org-3.4.repo"
  }

  provisioner "file" {
    source="templates/mongod.conf"
    destination="/tmp/mongod.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/mongodb-org-3.4.repo /etc/yum.repos.d/mongodb-org-3.4.repo",
      "sudo cp /tmp/mongod.conf /etc/mongod.conf",
      "export PATH=$PATH:/usr/bin",
      # install nginx
      "sudo yum install -y mongodb-org",
      "sudo service mongod start"
    ]
  }
  tags {
    Name = "mongodb-1"
  }

}


output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
