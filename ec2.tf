data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              
              # 1. Update system and install dependencies
              apt-get update && apt-get upgrade -y
              apt-get install -y git curl nginx mysql-client

              # 2. Install Node.js & npm (v17 via nvm for the 'ubuntu' user)
              sudo -i -u ubuntu bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash'
              sudo -i -u ubuntu bash -c 'source ~/.nvm/nvm.sh && nvm install v17'

              # 3. Clone the Application Repository
              cd /home/ubuntu
              sudo -i -u ubuntu git clone https://github.com/pravinmishraaws/theepicbook
              cd theepicbook

              # 4. Install Project Dependencies
              sudo -i -u ubuntu bash -c 'source ~/.nvm/nvm.sh && npm install'

              # 5. Set Up MySQL Database inside RDS
              # Strip port from endpoint for mysql client
              MYSQL_HOST=$$(echo ${aws_db_instance.mysql.endpoint} | cut -d: -f1)
              mysql -h $$MYSQL_HOST -u ${var.db_username} -p"${var.db_password}" -e "CREATE DATABASE IF NOT EXISTS bookstore;"
              mysql -h $$MYSQL_HOST -u ${var.db_username} -p"${var.db_password}" < /home/ubuntu/theepicbook/db/BuyTheBook_Schema.sql
              mysql -h $$MYSQL_HOST -u ${var.db_username} -p"${var.db_password}" < /home/ubuntu/theepicbook/db/author_seed.sql
              mysql -h $$MYSQL_HOST -u ${var.db_username} -p"${var.db_password}" < /home/ubuntu/theepicbook/db/books_seed.sql

              # 6. Set Up Nginx as a Reverse Proxy
              cat << 'NGINX_CONF' > /etc/nginx/sites-available/theepicbook.conf
              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://localhost:8080;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $$http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $$host;
                      proxy_cache_bypass $$http_upgrade;
                  }
              }
              NGINX_CONF

              rm -f /etc/nginx/sites-enabled/default
              ln -s /etc/nginx/sites-available/theepicbook.conf /etc/nginx/sites-enabled/
              
              systemctl restart nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "EpicBook-App-Server"
  }
}

resource "aws_eip" "app_server_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "epicbook-eip"
  }
}
