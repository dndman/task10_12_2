#!/bin/bash

. ./config

#all environment will be some later, after the main job will work
#installing docker
apt-get update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get -y install docker-ce

#installing bridge-utils(i dont care if it not need. just so)
#apt-get -y install bridge-utils
#echo "
#auto dockerbridge


#installing docker-compose
#apt-get -y install python-pip
#pip install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#making logfiles
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log

#making a conf file for nginx
mkdir -p /etc/nginx/conf
touch /etc/nginx/conf/nginx.conf
echo "
server {

    server_name $(hostname -f);
#    listen $NGINX_PORT;
    listen 443 ssl;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

     ssl_certificate     /etc/ssl/certs/$(hostname -f).crt;
     ssl_certificate_key /etc/ssl/certs/selfCA.key;
     ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;

    location / {

        proxy_pass         http://web;
#        proxy_redirect     off;
        proxy_set_header   Host $(hostname -f);
        proxy_set_header   X-Real-IP $EXTERNAL_IP;
#        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
#        proxy_set_header   X-Forwarded-Host $server_name;

    }
}

" > /etc/nginx/conf/nginx.conf

#making docker-compose.yml

echo "

version: '3'

services:
  proxy:
    image: $NGINX_IMAGE
    ports:
#      - \"$NGINX_PORT:$NGINX_PORT\" 
      - \"$NGINX_PORT:443\"
    volumes:
      - /etc/nginx/conf/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /var/log/nginx/:/var/log/nginx/
      - /etc/ssl/certs/$(hostname -f).crt:/etc/ssl/certs/$(hostname -f).crt
      - /etc/ssl/certs/selfCA.key:/etc/ssl/certs/selfCA.key



#      - /var/log/nginx/error.log:/var/log/nginx/error.log


  web:
    image: $APACHE_IMAGE




" > docker-compose.yml

./added
#launch docker-compose
#cd /workdir in future there will be a correct way to working dir
docker-compose up -d


