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

## Search for the latest Amazon Linux 2 image. No need to hardcode anything.
data "aws_ami" "linux" {
    most_recent = "true"
    owners =["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm*"]
    }
}

## Creates a certificate using the venafi provider for defined CN.
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
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
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

## Security group for EC2 instance (Apache server). This security only allow you to access the instance via the load balancer.
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

## AWS Load Balancer listener for HTTPS. This is secured with the Venafi created certificate that was imported to ACM.
resource "aws_lb_listener" "external-listener-https" {
    load_balancer_arn = "${aws_lb.external-alb.arn}"
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = "${aws_acm_certificate.cert.arn}"

    default_action {
        type = "forward"
        target_group_arn = "${aws_lb_target_group.external-target.arn}"
    }
}

## AWS Load Balancer listener for HTTP. This redirects HTTP traffic as HTTPS.
resource "aws_lb_listener" "external-listener-http-redirect" {
    load_balancer_arn = "${aws_lb.external-alb.arn}"
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
resource "aws_lb_target_group" "external-target" {
    name = "tf-example-lb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = "${module.vpc.vpc_id}"
}

## Creation of external facing Application Load Balancer.
resource "aws_lb" "external-alb" {
    name = "sample-lb-tf"
    internal = false
    load_balancer_type = "application"
    security_groups = ["${aws_security_group.allow_tls.id}"]
    subnets = ["${module.vpc.public_subnets[0]}","${module.vpc.public_subnets[1]}"]
}

## Target group attachment reference for Apache server and ALB.
resource "aws_lb_target_group_attachment" "ec2-tg-attachment" {
    target_group_arn = "${aws_lb_target_group.external-target.arn}"
    target_id = "${aws_instance.apache-server.id}"
    port = 80
}

## Apache server EC2 instance.
resource "aws_instance" "apache-server" {
    ami = "${data.aws_ami.linux.id}"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.ec2-instance-http.id}"]
    subnet_id = "${module.vpc.public_subnets[0]}"
    associate_public_ip_address = true
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

output "instance-alb-url" {
    value = "${aws_lb.external-alb.dns_name}/index.html"
}