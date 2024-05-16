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
rm -rf go1.20.14.linux-amd64.tar.gz

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
reboot
