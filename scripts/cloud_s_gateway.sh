#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 172.30.30.1

## Currently no NAT
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

# Forward client A to server-s1
iptables -A PREROUTING -t nat -p tcp -s 172.16.16.16 -d 172.30.30.30 --dport 8080 -j DNAT --to-destination 192.168.10.2:8888

# Forward client B to server-s2
iptables -A PREROUTING -t nat -p tcp -s 172.18.18.18 -d 172.30.30.30 --dport 8080 -j DNAT --to-destination 192.168.10.2:9999

# Only accept the packets designated to port 8888 and 9999 and drop all the others
iptables -t filter -A FORWARD -d 192.168.10.2 -p tcp -j ACCEPT
iptables -t filter -A FORWARD -s 192.168.10.2 -p tcp -j ACCEPT
iptables -t filter -A FORWARD -d 192.168.10.2 -p udp -j ACCEPT
iptables -t filter -A FORWARD -s 192.168.10.2 -p udp -j ACCEPT
iptables -t filter -P FORWARD DROP

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Defining pre-shared secrets for authentication
cat << EOF > /etc/ipsec.secrets
172.30.30.30 172.16.16.16 : PSK "B7A4C2B5F087DE8633957C011CBB7F83A0527EA94A1E81012CE0CB3E9FC86577"
172.30.30.30 172.18.18.18 : PSK "76C58728629E629F26012A2F52E436B6F413757107C5A8314EC5F1F170DD6471"
EOF

# Defining ipsec configuration
cat << EOF > /etc/ipsec.conf
config setup 
        charondebug=all 
        uniqueids=yes 
        strictcrlpolicy=no 

conn gateway-A-to-cloud 
        type=tunnel 
        keyexchange=ikev2 
        authby=secret 
        left=172.16.16.16 
        leftsubnet=172.16.16.16/32 
        right=172.30.30.30 
        rightsubnet=172.30.30.30/32
        ike=aes256-sha2_256-modp2048! 
        esp=aes256-sha2_256!
        dpdaction=restart 
        auto=start

conn gateway-B-to-cloud 
        type=tunnel 
        keyexchange=ikev2 
        authby=secret 
        left=172.18.18.18 
        leftsubnet=172.18.18.18/32 
        right=172.30.30.30 
        rightsubnet=172.30.30.30/32
        ike=aes256-sha2_256-modp2048! 
        esp=aes256-sha2_256!
        dpdaction=restart 
        auto=start
EOF

# Restart ipsec service
sudo systemctl restart ipsec
