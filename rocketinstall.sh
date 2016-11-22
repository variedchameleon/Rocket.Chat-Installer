#!/bin/bash

# Script assumes only one configured network interface and the loopback device is configured
# Additionally it will automatically open firewall ports along with redirecting the default install port (3000) to port 80 (http)

# Install prerequisites
yum install wget build-essential epel-release -y

# Install needed packages
yum install nodejs curl GraphicsMagick npm mongodb-org mongodb-server -y

# Start mongodb and set it to run on boot
systemctl start mongod
systemctl enable mongod

# Install some needed node modules
npm install -g inherits
npm install -g n

# Download and extract the latest Rocket.Chat release
cd /tmp
curl -L https://rocket.chat/releases/latest/download -o rocket.chat.tgz
tar xvzf rocket.chat.tgz

# Move the code to /opt/Rocket.Chat and install dependencies
mv bundle /opt/Rocket.Chat
cd /opt/Rocket.Chat/programs/server
npm install

# Save the local IP address to a variable so we can insert it into config files
IP_ADDR=$(ip a | grep inet | grep -v inet6 | grep -v 127 | awk {'print $2'} | sed 's/\/.*//')

# Create a systemd service so we can set Rocket.Chat to run on boot
cat >/usr/lib/systemd/system/rocketchat.service << EOF
[Unit]
Description=The Rocket.Chat Server
After=network.target remote-fs.target nss-lookup.target nginx.target mongod.target
[Service]
ExecStart=/bin/node /opt/Rocket.Chat/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=root
Group=root
Environment=MONGO_URL=mongodb://localhost:27017/rocketchat ROOT_URL=http://$IP_ADDR:3000/ PORT=3000
[Install]
WantedBy=multi-user.target
EOF

# Open up firewall ports and redirect
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 3000 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 3000 -j REDIRECT --to-port 80

# Start Rocket.Chat and set it to run on boot
systemctl enable rocketchat
systemctl start rocketchat

echo "Connect to your new chat server in your browser at http://LOCAL_IP:3000, any logs or errors will be in /var/log/messages"