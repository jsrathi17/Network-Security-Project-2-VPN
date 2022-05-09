#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 192.168.10.1

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

#installing docker
cd /home/vagrant
sudo curl -sSL https://get.docker.com/ | sh

#build docker image
cd /home/vagrant/server_app
sudo docker build . -t cloud_server_app

##run containers
# server 1
sudo docker run -p 8888:8080 -d cloud_server_app 

#server 2
sudo docker run -p 9999:8080 -d cloud_server_app 