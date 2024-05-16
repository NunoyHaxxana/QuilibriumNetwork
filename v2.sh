#!/bin/bash

# 1. Install git and wget
sudo apt-get update
sudo apt-get install -y git wget

# 2. Install Go
wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
sudo tar -xvf go1.20.14.linux-amd64.tar.gz
rm -rf /usr/local/go
mv go /usr/local/
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

# 3. Set sysctl settings
CHECK1="net.core.rmem_max=600000000"
CHECK2="net.core.wmem_max=600000000"
if ! grep -q "$CHECK1" /etc/sysctl.conf; then
    echo "$CHECK1" | sudo tee -a /etc/sysctl.conf
fi
if ! grep -q "$CHECK2" /etc/sysctl.conf; then
    echo "$CHECK2" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p

# 4. Clone and run Ceremony Client repository
cd /root/
git clone https://github.com/QuilibriumNetwork/ceremonyclient.git 
cd /root/ceremonyclient/node/
source ~/.bashrc
sleep 10
GOEXPERIMENT=arenas go install ./...

# 7. Create systemd service
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory=/root/ceremonyclient/node
Environment="GOEXPERIMENT=arenas"
ExecStart=/root/go/bin/node GOEXPERIMENT=arenas go run ./...

[Install]
WantedBy=multi-user.target
EOF

# 8. Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable ceremonyclient.service
sudo systemctl start ceremonyclient.service
sleep 300
sudo systemctl stop ceremonyclient.service


# 5. Update configuration
CONFIG_FILE="/root/ceremonyclient/node/.config/config.yml"
if ! grep -q "listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337" "$CONFIG_FILE"; then
  sed -i '/listenGrpcMultiaddr:/c\listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337' "$CONFIG_FILE"
fi
if ! grep -q "listenRESTMultiaddr: /ip4/127.0.0.1/tcp/8338" "$CONFIG_FILE"; then
  sed -i '/listenRESTMultiaddr:/c\listenRESTMultiaddr: /ip4/127.0.0.1/tcp/8338' "$CONFIG_FILE"
fi


sleep 30
sudo systemctl start ceremonyclient.service
clear
echo " "
echo " "
status=$(systemctl status ceremonyclient.service)

# Check if the service is active and running
if echo "$status" | grep -q "Active: active (running)"; then
    echo "Your node is running normally."
else
    echo "Your node is not running normally."
fi

echo " "
echo " "
cd /root/ceremonyclient/node
output=$(GOEXPERIMENT=arenas go run ./... -peer-id)
peer_id=$(echo "$output" | grep "Peer ID" | awk '{print $3}')
echo "Your Node Id : $peer_id"
