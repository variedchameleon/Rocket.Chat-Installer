#!/bin/bash

# Script assumes only one configured network interface and the loopback device is configured
# Additionally it will automatically open firewall ports along with redirecting the default install port (3000) to port 80 (http)
# Recommended to install on a fresh VM or machine

# Use Snaps to install Rocket.Chat Server for Ubuntu, Debian, RPM, Pacman based distros
sudo snap install rocketchat-server

# Configure iptables to open and forward ports to make http accessible
sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport 3000 -j ACCEPT
sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3000