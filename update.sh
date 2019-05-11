#/bin/bash

#Setup Variables
GREEN='\033[0;32m'
YELLOW='\033[0;93m'
RED='\033[0;31m'
NC='\033[0m'

echo -e ${YELLOW}"Welcome to SecureCloud-2.5.0.2 Automated Update."${NC}
echo "Please wait while updates are performed..."
echo "Stopping the node"
securecloud-cli stop
sleep 10
echo "Removing current binaries..."
cd /usr/local/bin
rm -rf securecloudd securecloud-cli securecloud-tx
echo "Downloading latest binaries"
wget $(curl -s https://api.github.com/repos/securecloudnet/SecureCloud/releases/latest | grep "browser_download_url.*\.tar\.gz"| cut -d '"' -f 4)
tar -xzf SecureCloud-linux.tar.gz
sudo chmod 755 -R securecloud*
rm -rf SecureCloud-linux.tar.gz
cd ~
echo "Startin/Syncing the node, please wait...";
securecloudd -daemon
until securecloud-cli mnsync status | grep -m 1 '"IsBlockchainSynced": true,'; do sleep 5 ; done > /dev/null 2>&1
echo -e ${GREEN}"Your node is fully synced. Your masternode is running!"${NC}
rm -rf /root/update.sh
echo -e ${GREEN}"The END. You can close now the SSH terminal session"${NC};
