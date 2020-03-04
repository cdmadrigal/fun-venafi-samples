## Define your providers. In this example we use the Venafi provider and AWS.
provider "venafi" {
    api_key = ""
    zone = ""
    url = ""
}

provider "aws" {
    version = "~> 2.0"
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

## Keypair to SSH in to jumpserver to access internal load balancer.
variable "key_pair" {
    type = "string"
}

## Search for the latest Amazon Linux 2 image. No need to hardcore anything.
data "aws_ami" "linux" {
    most_recent = "true"
    owners =["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm*"]
    }
}

## Creates a certificate using the Venafi provider for defined CN.
resource "venafi_certificate" "webserver" {
    common_name = "terraform.example.com"
    algorithm = "RSA"
    rsa_bits = "2048"
    san_dns = [
        "web1.terraform.example.com",
        "web2.terraform.example.com"
    ]
}

## Venafi created certificate is imported to AWS ACM for futher use by AWS services.
resource "aws_acm_certificate" "cert" {
    private_key = "${venafi_certificate.webserver.private_key_pem}"
    certificate_body = "${venafi_certificate.webserver.certificate}"
    certificate_chain = "${venafi_certificate.webserver.chain}"
}

## Security group for Application Load Balancer.
resource "aws_security_group" "allow_tls" {
    name = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id = "${module.vpc.vpc_id}"

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

## Security group for EC2 instance (Apache server). This security only allows you to access the instance via the load balancer.
resource "aws_security_group" "ec2-instance-http" {
    name = "ec2-instance-sg"
    description = "Allows inbound HTTP access"
    vpc_id = "${module.vpc.vpc_id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = ["${aws_security_group.allow_tls.id}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

## Security group for EC2 instance (Jumpserver). This security only allows SSH access; use the keypair you defined as a variable to access this box.
resource "aws_security_group" "ec2-jumpbox-sg" {
    name = "ec2-jumpbox-sg"
    description = "Allows SSH access to jumpbox."
    vpc_id = "${module.vpc.vpc_id}" 

    ingress {
        from_port = 22
        to_port = 22
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

## AWS Load Balancer listener for HTTPS. This is secured with the Venafi created certificate that was imported to ACM.
resource "aws_lb_listener" "internal-listener" {
    load_balancer_arn = "${aws_lb.internal-alb.arn}"
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = "${aws_acm_certificate.cert.arn}"

    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.internal-target.arn}"
    }
}

## AWS Load Balancer listener for HTTP. This redirects HTTP traffic as HTTPS.
resource "aws_lb_listener" "internal-listener-http-redirect" {
    load_balancer_arn = "${aws_lb.internal-alb.arn}"
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "redirect"

        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

## Target Group for Apache server.
resource "aws_lb_target_group" "internal-target" {
    name = "tf-example-lb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = "${module.vpc.vpc_id}"
}

## Creation of internal Application Load Balancer.
resource "aws_lb" "internal-alb" {
    name = "sample-lb-tf"
    internal = true
    load_balancer_type = "application"
    security_groups = ["${aws_security_group.allow_tls.id}"]
    subnets = ["${module.vpc.private_subnets[0]}","${module.vpc.private_subnets[1]}"]
}

## Target group attachment reference for Apache server and ALB.
resource "aws_lb_target_group_attachment" "ec2-tg-attachment" {
    target_group_arn = "${aws_lb_target_group.internal-target.arn}"
    target_id = "${aws_instance.apache-server.id}"
    port = 80
}

## Apache server EC2 instance. This is deployed on a private subnet.
resource "aws_instance" "apache-server" {
    ami = "${data.aws_ami.linux.id}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.ec2-instance-http.id}"]
    subnet_id = "${module.vpc.private_subnets[0]}"
    associate_public_ip_address = false
    tags = {
        Name = "Sample Apache Server"
    }
    user_data = <<EOF
            #! /bin/bash
            yum update -y
            yum -y install httpd
            service httpd start
            echo '<html><h1>Hello World!</h1></html>' > var/www/html/index.html
    EOF
}

## Bastion/Jumpbox server EC2 instance. This is deployed on a public subnet. SSH in to this instance to access the apache server.
resource "aws_instance" "jumpbox" {
    ami = "${data.aws_ami.linux.id}"
    instance_type = "t2.micro"
    key_name = "${var.key_pair}"
    vpc_security_group_ids = ["${aws_security_group.ec2-jumpbox-sg.id}"]
    subnet_id = "${module.vpc.public_subnets[0]}"
    associate_public_ip_address = true
    tags = {
        Name = "AWS Jump Server"
    }
    user_data = <<EOF
            #! /bin/bash
            yum update -y
    EOF
}