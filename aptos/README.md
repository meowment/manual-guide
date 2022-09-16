
# Aptos fullnode setup for Devnet
Official documents:
> [Run a full node](https://aptos.dev/tutorials/run-a-fullnode)

Usefull tools:
> To find latest block height use [Aptos Network Dashboard](https://status.devnet.aptos.dev/)\
> To check your node health status try [Aptos Node Informer](http://node-tools.net/aptos/tester/)\

## Hardware requirements:
#### For running a production grade Fullnode we recommend the following:
- CPU: 4 cores (Intel Xeon Skylake or newer)
- Memory: 8GiB RAM

#### If running the Fullnode for development or testing purpose:
- CPU: 2 cores
- Memory: 4GiB RAM

## Set up your aptos fullnode
### Option 1 (automatic)
Use script below for a quick installation
```
wget -qO aptos.sh https://raw.githubusercontent.com/kj89/testnet_manuals/main/aptos/aptos.sh && chmod +x aptos.sh && ./aptos.sh
```

### Option 2 (manual)
You can follow [manual guide](https://github.com/kj89/testnet_manuals/blob/main/aptos/manual_install.md) if you better prefer setting up node manually

## Update Aptos Fullnode version
```
wget -qO update.sh https://raw.githubusercontent.com/kj89/testnet_manuals/main/aptos/tools/update.sh && chmod +x update.sh && ./update.sh
```

## Useful commands
### Check Aptos logs
```
docker logs -f aptos-fullnode --tail 50
```

### Check sync status
```
curl 127.0.0.1:9101/metrics 2> /dev/null | grep aptos_state_sync_version | grep type
```

### Restart service
```
docker restart aptos-fullnode
```

### Delete node
```
docker stop aptos-fullnode
docker rm aptos-fullnode -f
docker volume rm aptos-fullnode -f
cd $HOME && rm aptos-fullnode -rf
```
