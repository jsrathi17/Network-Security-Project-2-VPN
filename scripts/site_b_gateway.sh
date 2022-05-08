#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.18.18.1
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6


# Defining pre-shared secrets for authentication
cat << EOF > /etc/ipsec.secrets
172.30.30.30 172.18.18.18 : PSK "76C58728629E629F26012A2F52E436B6F413757107C5A8314EC5F1F170DD6471 "
EOF

# Defining ipsec configuration
cat << EOF > /etc/ipsec.conf
config setup 
        charondebug=all 
        uniqueids=yes 
        strictcrlpolicy=no 

conn gateway-B-to-cloud 
        type=tunnel 
        keyexchange=ikev2 
        authby=secret 
        left=172.30.30.30 
        leftsubnet=172.30.30.30 
        right=172.18.18.18 
        rightsubnet=172.18.18.18/32
        ike=aes256-sha2_256-modp2048! 
        esp=aes256-sha2_256!
        dpdaction=restart 
        auto=start
EOF

# Restart ipsec service
systemctl restart ipsec
