#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.16.16.1
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

# forward the incoming packets to the old IP, to cloud
iptables -t nat -A PREROUTING -p tcp -d 10.1.0.99 --dport 8080 -j DNAT --to 172.30.30.30:8080


## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# Defining pre-shared secrets for authentication
cat << EOF > /etc/ipsec.secrets
172.30.30.30 172.16.16.16 : PSK "B7A4C2B5F087DE8633957C011CBB7F83A0527EA94A1E81012CE0CB3E9FC86577"
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
        left=172.30.30.30 
        leftsubnet=172.30.30.30/32
        right=172.16.16.16 
        rightsubnet=172.16.16.16/32
        ike=aes256-sha2_256-modp2048! 
        esp=aes256-sha2_256!
        dpdaction=restart r 
        auto=start
EOF

# Restart ipsec service
sudo systemctl restart ipsec
