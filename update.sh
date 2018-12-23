#/bin/bash

cd ~
cd /usr/local/bin
./securecloud-cli stop
rm -rf securecloudd securecloud-cli securecloud-tx
wget https://github.com/securecloudnet/SecureCloud/releases/download/2.1.0/securecloud-2.1.0-x86_64-linux-gnu.tar.gz
tar -xzf securecloud-2.1.0-x86_64-linux-gnu.tar.gz
rm -rf securecloud-2.1.0-x86_64-linux-gnu.tar.gz
./securecloudd -daemon
sleep 30
./securecloud-cli getinfo
