#!/bin/bash

echo "Elasticsearch needs at least 2GB of RAM to run!"

# Prerequsisites
apt update
apt install -y apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen dirmngr curl

# MongoDB
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/3.6 main" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list
apt-get update
apt-get install -y mongodb-org
systemctl daemon-reload
systemctl enable mongod.service
systemctl restart mongod.service

# Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
apt update && apt install -y elasticsearch

# Configure Elasticsearch
sed -i 's/\#cluster\.name:\ my-application/cluster\.name:\ graylog/g' /etc/elasticsearch/elasticsearch.yml

systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service

# Graylog
wget https://packages.graylog2.org/repo/packages/graylog-2.4-repository_latest.deb
dpkg -i graylog-2.4-repository_latest.deb
apt update && apt install -y graylog-server

# Configure Graylog
sed -i -e "s/password_secret =.*/password_secret = $(pwgen -s 128 1)/" /etc/graylog/server/server.conf
echo ""
echo "Please enter password for Graylog:"
echo ""
read Password
GrayPass=$Password

echo "$GrayPass" > /root/GrayPassword.txt

sed -i -e "s/root_password_sha2 =.*/root_password_sha2 = $(echo -n "$GrayPass" | shasum -a 256 | cut -d' ' -f1)/" /etc/graylog/server/server.conf

MyIP=$(curl ifconfig.co)

sed -i "s/127\.0\.0\.1/${MyIP}/g" /etc/graylog/server/server.conf
sed -i 's/#web_listen_uri/web_listen_uri/g' /etc/graylog/server/server.conf

systemctl enable graylog-server
systemctl restart graylog-server

echo ""
echo "Your link: http://${MyIP}:9000"
echo "Your password: ${GrayPass}"
echo ""
