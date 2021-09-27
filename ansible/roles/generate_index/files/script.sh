#!/bin/bash
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>WebServer with internal AWS IP: $myip</h2><br>Build by AWS+Terraform+Ansible!"  >  /var/www/html/index.nginx-debian.html
sudo nginx -s reload
