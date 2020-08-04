#!/bin/bash
yum update -y
yum install -y httpd
VAR1="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "<html><body>$VAR1</body></html>" > /var/www/html/index.html
service httpd start
chkconfig httpd on