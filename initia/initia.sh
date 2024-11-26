#!/bin/bash
echo -e "\e[92m"
echo "  ___ ___    ___  __ __      __ ___ ___   ___ ___  | |_   ";
echo " |  _ \ _ \ / _ \/ _ \ \ /\ / /  _ \ _ \ / _ \  _ \| __|  ";
echo " | | | | | |  __/ (_) \ V  V /| | | | | |  __/ | | | |_   ";
echo " |_| |_| |_|\___|\___/ \_/\_/ |_| |_| |_|\___|_| |_|\__|  ";
echo -e "\e[0m"


sleep 2

echo "Updating and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install clang pkg-config libssl-dev curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

if ! command -v go &> /dev/null || [[ $(go version | awk '{print $3}' | cut -d. -f2) -lt 19 ]]; then
    echo "Go version 1.19 or above is required. Installing the latest version..."
    cd $HOME
    sudo rm -rf /usr/local/go
    curl -Ls https://go.dev/dl/go1.21.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
    echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile
    source /etc/profile.d/golang.sh
    source $HOME/.profile
fi

if ! command -v go &> /dev/null; then
    echo "Failed to install Go. Exiting..."
    exit 1
fi

echo "Go version: $(go version)"

if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing..."
    sudo apt update
    sudo apt install -y git
fi

if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Installing..."
    sudo apt update
    sudo apt install -y curl
fi

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    sudo apt update
    sudo apt install -y jq
fi

cd $HOME
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.15
make install
initiad version --long

read -p "Enter moniker for your node: " moniker
initiad init "$moniker" --chain-id initiation-1

wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json
cp genesis.json ~/.initia/config/genesis.json

sed -i -e 's/external_address = \"\"/external_address = \"'$(curl httpbin.org/ip | jq -r .origin)':26656\"/g' ~/.initia/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" ~/.initia/config/app.toml

curl -Ls https://ss-t.initia.nodestake.org/addrbook.json > ~/.initia/config/addrbook.json

sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia Daemon

[Service]
Type=simple
User=$(whoami)
ExecStart=$(go env GOPATH)/bin/initiad start
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=initiad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# reset and download snapshot
initiad tendermint unsafe-reset-all --home $HOME/.initia
curl -L https://snapshots.polkachu.com/testnet-snapshots/initia/initia_237655.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.initia

# enable and start service
sudo systemctl enable initiad
sudo systemctl daemon-reload
sudo systemctl restart initiad
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc && source ~/.bashrc

echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc && source ~/.bashrc

echo "Initia setup completed successfully."
sudo journalctl -u initiad -f
