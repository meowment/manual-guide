#!/bin/bash

GREEN="\e[32m"
LIGHT_GREEN="\e[92m"
YELLOW="\e[33m"
DEFAULT="\e[39m"

function install_node {
   echo "*********************"
   echo -e "\e[1m\e[33m	WARNING!!!! THIS NODE IS INSTALLED IN PORT 20657!!!!\e[0m"
   echo "*********************"
   echo -e "\e[1m\e[32m	Enter your Node Name:\e[0m"
   echo "_|-_|-_|-_|-_|-_|-_|"
   read MONIKER
   echo "_|-_|-_|-_|-_|-_|-_|"
   echo export MONIKER=${MONIKER} >> $HOME/.bash_profile
   source ~/.bash_profile


    echo "Installing Depencies..."
    sudo apt update
    sudo apt install curl git jq lz4 build-essential snapd -y
    
    echo "Installing GO 19+ ..."
   if ! [ -x "$(command -v go)" ]; then
     ver="1.19.4"
     cd $HOME
     wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
     sudo rm -rf /usr/local/go
     sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
     rm "go$ver.linux-amd64.tar.gz"
     echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
     source ~/.bash_profile
   fi
    
    echo "Downloading and building binaries..."
    cd $HOME
	rm -rf hub
	git clone https://github.com/mars-protocol/hub.git
	cd hub
	git checkout v1.0.0-rc7
	
    echo "Build binaries.."
    make build
	mkdir -p $HOME/.mars/cosmovisor/genesis/bin
	mv build/marsd $HOME/.mars/cosmovisor/genesis/bin/
	rm -rf build
    
    echo "Install and building Cosmovisor..."
    go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0

# Create service
sudo tee /etc/systemd/system/marsd.service > /dev/null << EOF
[Unit]
Description=mars-testnet node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.mars"
Environment="DAEMON_NAME=marsd"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable marsd

    # Create application symlinks
    ln -s $HOME/.mars/cosmovisor/genesis $HOME/.mars/cosmovisor/current
    sudo ln -s $HOME/.mars/cosmovisor/current/bin/marsd /usr/local/bin/marsd
    
    echo "Configuring Node..."
    # Set node configuration
    marsd config chain-id ares-1
	marsd config keyring-backend test
	marsd config node tcp://localhost:20657

	# Initialize the node
	marsd init $MONIKER --chain-id ares-1

	wget -O $HOME/.mars/config/addrbook.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/addrbook.json"
	wget -O $HOME/.mars/config/genesis.json "https://raw.githubusercontent.com/elangrr/testnet_guide/main/mars/genesis.json"

	# Add seeds
	sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@mars-testnet.rpc.kjnodes.com:45659\"|" $HOME/.mars/config/config.toml

	# Set minimum gas price
	sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0umars\"|" $HOME/.mars/config/app.toml

	sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.mars/config/config.toml
	external_address=$(wget -qO- eth0.me) 
	sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.mars/config/config.toml
	sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.mars/config/config.toml


	# Set pruning
	sed -i -e "s|^pruning *=.*|pruning = \"custom\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-recent *=.*|pruning-keep-recent = \"100\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-keep-every *=.*|pruning-keep-every = \"0\"|" $HOME/.mars/config/app.toml
	sed -i -e "s|^pruning-interval *=.*|pruning-interval = \"19\"|" $HOME/.mars/config/app.toml

	# Set Indexer
	indexer="null" && \
	sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.mars/config/config.toml

	# Set custom ports 20
	sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:20658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:20657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:20060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:20656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":20660\"%" $HOME/.mars/config/config.toml
	sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:20317\"%; s%^address = \":8080\"%address = \":20080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:20090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:20091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:20545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:20546\"%" $HOME/.mars/config/app.toml


   echo "Starting Node..."
   sudo systemctl start marsd && journalctl -u marsd -f --no-hostname -o cat

}

function check_logs {

    sudo journalctl -fu marsd -o cat
}

function create_wallet {
    echo "Creating your wallet.."
    sleep 2
    
    marsd keys add wallet
    
    sleep 3
    echo "SAVE YOUR MNEMONIC!!!"


}

function state_sync {
    echo "SOON"
}

function sync_snapshot {
   echo " If you have state sync enabled please turn it off first"
   sleep 3
   sudo apt update
   sudo apt install snapd -y
   sudo snap install lz4
   
   sudo systemctl stop marsd
	cp $HOME/.mars/data/priv_validator_state.json $HOME/.mars/priv_validator_state.json.backup
	rm -rf $HOME/.mars/data

	curl -L https://snapshot.mars.indonode.net/mars-snapshot-2023-01-14.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mars
	mv $HOME/.mars/priv_validator_state.json.backup $HOME/.mars/data/priv_validator_state.json

	sudo systemctl restart marsd && journalctl -u marsd -f --no-hostname -o cat

}

function delete_node {
echo "BACKUP YOUR NODE!!!"
echo "Deleting node in 3 seconds"
sleep 3
cd $HOME
sudo systemctl stop marsd
sudo systemctl disable marsd
sudo rm /etc/systemd/system/marsd.service
sudo systemctl daemon-reload
sudo rm -rf $(which marsd) 
sudo rm -rf $HOME/.mars
sudo rm -rf $HOME/hub
echo "Node has been deleted from your machine :)"
sleep 3
}

function select_option {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function print_logo {
    echo -e $LIGHT_GREEN
    echo "  ___ ___    ___  __ __      __ ___ ___   ___ ___  | |_   ";
    echo " |  _ \ _ \ / _ \/ _ \ \ /\ / /  _ \ _ \ / _ \  _ \| __|  ";
    echo " | | | | | |  __/ (_) \ V  V /| | | | | |  __/ | | | |_   ";
    echo " |_| |_| |_|\___|\___/ \_/\_/ |_| |_| |_|\___|_| |_|\__|  ";
    echo -e $DEFAULT
}

function main {
    cd $HOME

    print_logo

    echo "Meowment Node Installer CLI"
    echo "Choose the command you want to use:"

    options=(
        "🚀 Install Mars Testnet Node Port 20"
        "📝 Check Logs"
        "🔑 Create wallet"
        "🖧 Sync Via State-sync "
        "🔎 Sync Via Snapshot"
        "🗑️ Delete Node"
        "🎯 Exit"
    )

    select_option "${options[@]}"
    choice=$?
    clear

    case $choice in
        0)
            install_node
            ;;
        1)
            check_logs
            ;;
        2)
            create_wallet
            ;;    
        3)
            state_sync
            ;;
        4)
            sync_snapshot
            ;;
        5)
            delete_node
            ;;    
        6)
            exit 0
            ;;
    esac

    echo -e $DEFAULT
}

main
