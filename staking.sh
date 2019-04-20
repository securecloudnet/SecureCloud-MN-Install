#/bin/bash

cd ~
  
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get install -y nano htop git
sudo apt-get install -y software-properties-common
sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
sudo apt-get install -y libboost-all-dev
sudo apt-get install -y libevent-dev
sudo apt-get install -y libminiupnpc-dev
sudo apt-get install -y autoconf
sudo apt-get install -y automake unzip
sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install -y libdb4.8-dev libdb4.8++-dev
sudo apt-get install libzmq3-dev

cd /var
sudo touch swap.img
sudo chmod 600 swap.img
sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
sudo mkswap /var/swap.img
sudo swapon /var/swap.img
sudo free
sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
cd

wget https://github.com/securecloudnet/SecureCloud/releases/download/v2.5.1/SecureCloud-linux.tar.gz
tar -xzf SecureCloud-linux.tar.gz

sudo apt-get install -y ufw
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw logging on
echo "y" | sudo ufw enable
sudo ufw status
sudo ufw allow 9191/tcp
  
cd
mkdir -p .securecloud
echo "staking=1" >> securecloud.conf
echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> securecloud.conf
echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> securecloud.conf
echo "rpcallowip=127.0.0.1" >> securecloud.conf
echo "listen=1" >> securecloud.conf
echo "server=1" >> securecloud.conf
echo "daemon=1" >> securecloud.conf
echo "logtimestamps=1" >> securecloud.conf
echo "maxconnections=256" >> securecloud.conf
echo "port=9191" >> securecloud.conf
echo "addnode=149.28.238.247" >> securecloud.conf
echo "addnode=45.77.59.64" >> securecloud.conf
echo "addnode=45.63.119.225" >> securecloud.conf
echo "addnode=45.76.131.16" >> securecloud.conf
mv securecloud.conf .securecloud

  
cd
./securecloudd -daemon
sleep 30
./securecloud-cli getinfo
sleep 5
./securecloud-cli getnewaddress
echo "Use the address above to send your SCN coins to this server"
