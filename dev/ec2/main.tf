resource "aws_instance" "go_mysql_api" {
	ami = var.ec2_instance_ami.id
	instance_type               = var.ec2_instance_type.id
	subnet_id                   = aws_subnet.public_subnet.id
	associate_public_ip_address = true
	key_name                    = aws_key_pair.ec2_key_pair.key_name
	iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  
	vpc_security_group_ids = [
	  aws_security_group.default.id
	]
	
	root_block_device {
	  delete_on_termination = true
	  volume_size = 10
	  volume_type = "gp2"
	}

	tags = {
	  Name = "${var.environment}-${var.service_name}-ec2"
	  Environment = var.environment
	  Service = var.service_name
	  CreatedBy = var.infra_builder
	}
  
	depends_on = [aws_security_group.default, aws_key_pair.ec2_key_pair]
	user_data = base64encode(templatefile("user_data.sh", {
	  DB_USER = aws_db_instance.mysql_8.username
	  # This is the parameter store path for the password securely stored for database connection.
	  DB_PASSWORD_PARAM = data.aws_ssm_parameter.db_password.name 
	  DB_HOST = aws_db_instance.mysql_8.address
	  DB_PORT = aws_security_group_rule.allow_mysql_in.from_port
	  DB_NAME = aws_db_instance.mysql_8.db_name
	}))
  }
  
  resource "aws_key_pair" "ec2_key_pair" {
	key_name   = "ec2_key_pair"
	public_key = tls_private_key.rsa.public_key_openssh
  }
  
  resource "tls_private_key" "rsa" {
	algorithm = "RSA"
	rsa_bits  = 4096
  }

  resource "local_sensitive_file" "tf_key" {
	content              = tls_private_key.rsa.private_key_pem
	file_permission      = "600"
	directory_permission = "700"
	filename             = "${aws_key_pair.ec2_key_pair.key_name}.pem"
  }
  
  data "aws_ssm_parameter" "db_password" {
	name        = "/opt/goapi/db/password"
  }
  
  # Create an IAM instance profile for the EC2 instance
  resource "aws_iam_instance_profile" "instance_profile" {
	name = var.ec2_instance_profile_name.id
	role = aws_iam_role.instance_role.name
  }
  
  # Create an IAM role for the EC2 instance
  resource "aws_iam_role" "instance_role" {
	name = var.ec2_instance_role_name.id
  
	assume_role_policy = <<EOF
  {
	"Version": "2012-10-17",
	"Statement": [
	  {
		"Effect": "Allow",
		"Principal": {
		  "Service": "ec2.amazonaws.com"
		},
		"Action": "sts:AssumeRole"
	  }
	]
  }
  EOF
  }
  
resource "aws_iam_role_policy_attachment" "instance_policy_attachment" {
	role       = aws_iam_role.instance_role.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}