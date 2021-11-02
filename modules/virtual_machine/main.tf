terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Create virtual private cloud (vpc)
resource "aws_vpc" "vpc_cicd" {
  cidr_block = "10.0.0.0/16" #or 10.0.0.0/16
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
      Name = "cicd-private-cloud"
  }
}

# Assign gateway to vp
resource "aws_internet_gateway" "gw_cicd" {
  vpc_id = aws_vpc.vpc_cicd.id
  
  tags = {
      Name = "cicd-igw"
  }
}

# ---------------------------------------- Step 1: Create two subnets ----------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# Note: An Availability Zone is represented by an AWS Region code followed by a letter identifier (for example, us-east-1a).
resource "aws_subnet" "subnet_cicd" {
  vpc_id            = aws_vpc.vpc_cicd.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a" #data.aws_availability_zones.available.names[0]
  depends_on        = [aws_internet_gateway.gw_cicd]

  map_public_ip_on_launch = true

  tags = {
      Name = "cicd-public-1"
  }
}

# ---------------------------------------- Step 2: Create ACL network/ rules ----------------------------------------
resource "aws_network_acl" "cicd_acl_network" {
  vpc_id = aws_vpc.vpc_cicd.id
  subnet_ids = [aws_subnet.subnet_cicd.id] #assign the created subnets to the acl network otherwirse the NACL is assigned to a default subnet

  tags = {
    Name = "cicd-network-acl"
  }
}

# Create acl rules for the network
# ACL inbound
resource "aws_network_acl_rule" "all_inbound_traffic_acl_cicd" {
  network_acl_id = aws_network_acl.cicd_acl_network.id
  rule_number    = 180
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# ACL outbound
resource "aws_network_acl_rule" "all_outbound_traffic_acl_cicd" {
  network_acl_id = aws_network_acl.cicd_acl_network.id
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  rule_number    = 180
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# ---------------------------------------- Step 3: Create security group/ rules ----------------------------------------
resource "aws_security_group" "sg_cicd" {
    name   = "cicd-security-group"
    vpc_id = aws_vpc.vpc_cicd.id
}

# Inbound rules
# Create first (inbound) security rule to open port 22 for ssh connection request
resource "aws_security_group_rule" "ssh_inbound_rule_cicd" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["94.70.57.183/32", "79.129.48.158/32"] #"94.70.57.33/32", "79.129.48.158/32", "192.168.30.22/32", "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "security rule to open port 22 for ssh connection"
}

# Create second (inbound) security rule to allow pings of public ip address of ec2 instance from local machine
resource "aws_security_group_rule" "ping_public_ip_sg_rule_cicd" {
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"] #94.70.57.33/32", "79.129.48.158/32", "192.168.30.22/32, "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "allow pinging elastic public ipv4 address of ec2 instance from local machine"
}

resource "aws_security_group_rule" "jenkins_inbound_rule_cicd" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["94.70.57.183/32", "79.129.48.158/32", "140.82.112.0/20", "185.199.108.0/22", "192.30.252.0/22", "143.55.64.0/20"] #"94.70.57.33/32", "79.129.48.158/32", "192.168.30.22/32", "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "security rule to open port 8080 for http connection with Jenkins tool and GitHub webhooks."
}

resource "aws_security_group_rule" "smtp_inbound_rule_cicd" {
  type              = "ingress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #"94.70.57.33/32", "79.129.48.158/32", "192.168.30.22/32", "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "security rule to open port 587 for SMTP communication with Outlook.com email."
}

#--------------------------------

# Outbound rules
# Create first (outbound) security rule to open port 80 for HTTP requests (this will help to download packages while connected to vm)
resource "aws_security_group_rule" "http_outbound_rule_cicd" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #aws_vpc.vpc_cicd.cidr_block, "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "Security rule to open port 80 for outbound connection with http from remote server"
}

# Create second (outbound) security rule to open port 443 for HTTPS requests
resource "aws_security_group_rule" "https_outbound_rule_cicd" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #aws_vpc.vpc_cicd.cidr_block, "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "Security rule to open port 443 for outbound connection with https from remote server"
}

# Create third (outbound) security rule to open port 8080 for Jenkins service
resource "aws_security_group_rule" "jenkins_outbound_rule_cicd" {
  type              = "egress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] #aws_vpc.vpc_cicd.cidr_block, "0.0.0.0/0"
  security_group_id = aws_security_group.sg_cicd.id
  description       = "Security rule to open port 8080 for outbound connection between Jenkins and remote server"
}

# ---------------------------------------- Step 4: SSH key generated for accessing VM ----------------------------------------
resource "tls_private_key" "ssh_key_cicd" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------- Step 5: Generate aws_key_pair ----------------------------------------
resource "aws_key_pair" "generated_key_cicd" {
  key_name   = "${var.prefix}-server-ssh-key"
  public_key = tls_private_key.ssh_key_cicd.public_key_openssh

  tags   = {
    Name = "SSH key pair for cicd server"
  }
}

# ---------------------------------------- Step 6: Create network interface ----------------------------------------

# Create network interface
resource "aws_network_interface" "network_interface_cicd" {
  subnet_id       = aws_subnet.subnet_cicd.id
  security_groups = [aws_security_group.sg_cicd.id]
  description     = "cicd server network interface"

  tags   = {
    Name = "cicd-network-interface"
  }
}

# ---------------------------------------- Step 7: Create the Elastic Public IP after having created the network interface ----------------------------------------

resource "aws_eip" "cicd_server_public_ip" {
  vpc               = true
  network_interface = aws_network_interface.network_interface_cicd.id #don't specify both instance and a network_interface id, one of the two!
  
  depends_on        = [aws_internet_gateway.gw_cicd, aws_network_interface.network_interface_cicd]
  tags   = {
    Name = "cicd-elastic-ip"
  }
}

# ---------------------------------------- Step 8: Associate public ip to network interface ----------------------------------------

resource "aws_eip_association" "eip_assoc_cicd" {
  allocation_id = aws_eip.cicd_server_public_ip.id
  network_interface_id = aws_network_interface.network_interface_cicd.id # don't use instance_id and network_interface_id at the same time

  depends_on = [aws_eip.cicd_server_public_ip, aws_network_interface.network_interface_cicd]
}

# ---------------------------------------- Step 9: Create route table with rules ----------------------------------------

resource "aws_route_table" "route_table_cicd" {
  vpc_id = aws_vpc.vpc_cicd.id
  tags   = {
    Name = "route-table-cicd-server"
  }
}

/*documentation =>
https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html#Add_IGW_Routing
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html?icmpid=docs_ec2_console#ec2-instance-connect-setup-security-group
*/

# Assign internet gateway rule to route table
resource "aws_route" "route_cicd_all" {
  route_table_id         = aws_route_table.route_table_cicd.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw_cicd.id
  depends_on             = [
    aws_route_table.route_table_cicd, aws_internet_gateway.gw_cicd
  ]
}

# Create main route table association with the two subnets
resource "aws_main_route_table_association" "cicd-route-table" {
  vpc_id         = aws_vpc.vpc_cicd.id
  route_table_id = aws_route_table.route_table_cicd.id
}

resource "aws_route_table_association" "cicd-public-1-a" {
  subnet_id      = aws_subnet.subnet_cicd.id
  route_table_id = aws_route_table.route_table_cicd.id
}

# ---------------------------------------- Step 10: Create the AWS EC2 instance ----------------------------------------
resource "aws_instance" "cicd_server" {
  depends_on                  = [aws_eip.cicd_server_public_ip, aws_network_interface.network_interface_cicd, aws_security_group_rule.ssh_inbound_rule_cicd]
  ami                         = "ami-06d79c60d7454e2af" #"ami-00399ec92321828f5" #data.aws_ami.ubuntu-server.id, ami-0a5a9780e8617afe7
  #NOTE: https://cloud-images.ubuntu.com/locator/ec2/ to find valid ami's based on Region
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.generated_key_cicd.key_name

  #The block below fixes the error of attaching default network interface at index 0 
  network_interface {
    network_interface_id = aws_network_interface.network_interface_cicd.id
    device_index         = 0
  }

  # ebs_block_cicdice {
  #   cicdice_name = "/cicd/sda1"
  #   volume_type = "standard"
  #   volume_size = 8
  # }

  # Remote-exec seems to work only if all inbound traffic is allowed to ssh port of the ec2 instance
  # connection {
  #   type        = "ssh"
  #   host        = aws_eip.cicd_server_public_ip.public_ip //Error: host for provisioner cannot be empty -> https://github.com/hashicorp/terraform-provider-aws/issues/10977
  #   user        = "ubuntu"
  #   private_key = "${chomp(tls_private_key.ssh_key_cicd.private_key_pem)}"
  #   timeout     = "1m"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "echo Installing modules...",
  #     "sudo apt-get update",
  #     "sudo apt-get install -y openjdk-8-jdk",
  #     "sudo apt install -y python2",
  #     "sudo curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py",
  #     "sudo python2 get-pip.py",
  #     "sudo echo $(python2 --version) & echo $(pip2 --version)",
  #     "sudo apt install -y docker.io",
  #     "sudo systemctl start docker",
  #     "sudo systemctl enable docker",
  #     "pip install setuptools",
  #     "echo Modules installed via Terraform"
  #   ]
  #   on_failure = fail
  # }

  # User_data seems to work with the predefined ip address that have access only to the ssh port of the ec2 instance
  # Note: Jenkins will take time to be installed after the ec2 instance is created.
  user_data= <<-EOF
		#! /bin/bash
    echo -e "\tInstalling modules..."
    sudo apt-get update
    sudo apt-get install -y openjdk-8-jdk
    #sudo apt install -y python2
    #sudo curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
    #sudo python2 get-pip.py
    #sudo echo $(python2 --version) & echo $(pip2 --version)
    sudo apt install software-properties-common
    #sudo add-apt-repository --yes --update ppa:ansible/ansible
    #sudo apt install -y ansible
    sudo apt install -y python3 python3-pip
    pip3 install ansible
    sudo ansible --version
    pip install setuptools
    echo -e "\tExtract debian stable jenkins key"
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    echo -e "\tInstalling Jenkins tool"
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt upgrade -y
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl status jenkins
    echo -e "\tJenkins is running on default port: 8080"
    echo -e "\tModules installed via Terraform"
	EOF

  tags   = {
    Name = "cicd-server"
  }
}