#!/bin/bash

# Check if we are root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root." 1>&2
	exit 1
fi

namemoney="securecloud"

port=9191
rpcport=9291

node1="149.28.238.247"
node2="45.77.59.64"
node3="45.63.119.225"
node4="45.76.131.16"

# Set these to change the version of SecureCloud to install
TARBALLNAME="SecureCloud-linux.tar.gz"
TARBALLURL="https://github.com/securecloudnet/SecureCloud/releases/download/v2.5.1.1/"$TARBALLNAME

USERHOME=`eval echo "~$USER"`

configfile=$namemoney".conf"
pidfile=$namemoney".pid"
client=$namemoney"-cli"
server=$namemoney"d"

BOOTSTRAPURL="https://github.com/securecloudnet/SecureCloud/releases/download/v2.5.1/bootstrap-20190503.zip"
BOOTSTRAPARCHIVE="bootstrap-20190503.zip"
BWKVERSION="1.0.0"
cant=1

echo  "
                                        ,#%%%%%%%%%(,
                                    .##########(((##%%%#.
                                  /%#########((***/####%%%/
                    ,/#%%%%##%%#/%(//((((##(((((((####//#%%%
                 #%%%##*######(((((((////((#(((((((########%%,
              *&%%%%########(((((((//*,.,,*((##(/((((#######%%
            ,&%%%%%#######((((((((/((/*,,**//(###((((((####(#%%%%&%(.
           %%%%%%%######(((((//////((//////////##/((((((###(##%%%%%%%%
          #%%%%#%#####((((((//***,********/////#(//*/(((((######%%%%%%&&&&.
         #&%%#(/#####((((((///**,,,,,,********///*,,*/(((((######%%%%%%%&&&%
        .&%%%%#######((((//****////*****////////(((#((((((((#####%%%%%%%&&&&&.
        ,&%%%##((####((((/**,*/(((//*****,,****///((#/((((((///((##%%%%%#%&&@&
    *&&&&%%%#/**/((#((((((/////((///**,,,,,,,,**///((/((((//*,,*((#%%%&&&&&&@@.
 ,%&&&&&&%%%%########(((((/////((//**,,......,,**//((/((((((//(((#%%%%%&&%##&@*
*@@&&&%%#############((((((////((//**,,,......,,*//((/((((((#####%%%%%&&&%/(&@,
@@@&%##(//*/((#######((((((///(((//***,,,..,,,***//((/(((((#####%%%%%%&&&&&&@@
@@&&%#(/*,**/((#######((((((//(#((/*****,,,*****//((((((((#####%###%%%%&&&&&@(
@@@&&%%#((((#####(///(##((((((/##((////******///////(/(((#######(/*/#%%&&&&@*
%@@@@&&%%%%%%%%#/(//((###((((((/(((((/////////////*,,/((#####%%%####%&&&&&&,
 &@@@&&&&&&&&%%%%%%#######((((((((((/**////////((((((((#####%%%%%#(#&&&&&*
   %@@@@&&&&&&&%%%%%%########((((((((((((((((((((((#(######%%%%%%%&&&&*
                                  SecureCloud "
echo ""
echo This script create multiple
echo Master Node for SCN Money.
echo ""

read -p "How many Master Nodes do you want? [1/x] :" cant
read -p "Default directory of installation [${USERHOME}] :" USERHOME

if [ ! -d ${USERHOME} ] | [ -z ${USERHOME} ];
then
	USERHOME=`eval echo "~$USER"`
fi

if [ -z "$cant" ];
then
	cant=1
fi

while :
do
	read -p "Are you sure do want to create "$cant" Master Nodes ? [Y/n] :" INPUT_STRING
	case $INPUT_STRING in
		y)
			break
			;;
		n)
			exit 1
			;;
		*)
			INPUT_STRING=y
			break
			;;
	esac
done

cd

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get -y install wget htop unzip git dnsutils systemd pkg-config software-properties-common aptitude > /dev/null 2>&1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# CHARS is used for the loading animation further down.
CHARS="/-\|"

if [ -z "$EXTERNALIP" ]; then
   EXTERNALIP=`dig +short ANY myip.opendns.com @resolver1.opendns.com`
fi

ipmn=$EXTERNALIP

if [ -z "$1" ]
then
	echo "Installing dependencies."
	add-apt-repository -y ppa:bitcoin/bitcoin 
	apt-get -y update
	apt-get -y full-upgrade
	apt-get -y autoremove
	apt-get -y install autoconf automake autotools-dev build-essential libboost-all-dev libboost-program-options-dev \
		libdb4.8++-dev libdb4.8-dev libevent-dev libevent-pthreads-2.0-5 libminiupnpc-dev libprotobuf-dev libqrencode-dev \
		libqt4-dev libssl-dev libtool libzmq3-dev protobuf-compiler

	if [[ $(swapon -s | grep -ci -E "^\/swapfile" ) -eq 0 ]]
	then
	{
		echo "Creating Swap..."

		swap_size="2G"

		sudo fallocate -l $swap_size /swapfile
		sleep 2
		sudo chmod 600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		echo -e "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
	}
	fi

	sudo sysctl vm.swappiness=10
	sudo sysctl vm.vfs_cache_pressure=50
	echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
	echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1

	# Install SCN daemon
	rm -rf $TARBALLNAME > /dev/null 2>&1
	wget $TARBALLURL
	tar -xzvf $TARBALLNAME
	rm $TARBALLNAME > /dev/null 2>&1
	mv ./securecloudd /usr/local/bin
	mv ./securecloud-cli /usr/local/bin
	mv ./securecloud-tx /usr/local/bin
	mv ./securecloud-qt /usr/local/bin
	rm -rf $TARBALLNAME > /dev/null 2>&1

	echo "Getting bootstrap..."
	wget $BOOTSTRAPURL
fi

if [ $INPUT_STRING == "y" ]
then
	echo "Creating "$cant" Master Nodes"

	printf -v ini "%03d" 1

	dir="${USERHOME}/"

	if [ $cant -lt 1 ]
	then
		printf -v cant "%03d" 1
	else
		printf -v cant "%03d" $cant
	fi


	if [ -d $dir ]
	then

		dir="${USERHOME}/."$namemoney
		i=0
		for x in $( eval echo {$ini..$cant} )
		do
			i=$((i+1))

			echo "mkdir "$dir$x"/  > /dev/null 2>&1"|sh
			echo "rm "$dir$x"/*.conf  > /dev/null 2>&1"|sh

			newport=$((port + i))
			newportrpc=$((rpcport + i))

			RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
			RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

			echo "# Script Generated by Mutante (mod by ZioFabry)" > $dir$x"/"$configfile
			echo "" >> $dir$x"/"$configfile

			if [ "$i" -gt "1" ]
			then
				echo "listen=0" >> $dir$x"/"$configfile
			else
				echo "listen=1" >> $dir$x"/"$configfile
			fi

			echo "server=1" >> $dir$x"/"$configfile
			echo "daemon=1" >> $dir$x"/"$configfile
			echo "logtimestamps=1" >> $dir$x"/"$configfile
			echo "maxconnections=256" >> $dir$x"/"$configfile
			echo "staking=1" >> $dir$x"/"$configfile

			#IP and Ports
			echo "rpcuser="$RPCUSER >> $dir$x"/"$configfile
			echo "rpcpassword="$RPCPASSWORD >> $dir$x"/"$configfile
			echo "rpcallowip=127.0.0.1" >> $dir$x"/"$configfile
			echo "externalip="$ipmn >> $dir$x"/"$configfile
			echo "bind="$ipmn >> $dir$x"/"$configfile
			echo "masternodeaddr="$ipmn >> $dir$x"/"$configfile
			echo "rpcport="$newportrpc >> $dir$x"/"$configfile
			echo "port="$port >> $dir$x"/"$configfile

			#Nodes
			echo "addnode="$node1 >> $dir$x"/"$configfile
			echo "addnode="$node2 >> $dir$x"/"$configfile
			echo "addnode="$node3 >> $dir$x"/"$configfile
			echo "addnode="$node4 >> $dir$x"/"$configfile

			unzip $BOOTSTRAPARCHIVE -d $dir$x
		done

		rm -f $BOOTSTRAPARCHIVE

		echo
		echo Creating new Wallets and Master Nodes Keys, save thats addresses
		echo
		i=0
		for x in $( eval echo {$ini..$cant} )
		do
			i=$((i+1))
			ps -fea|grep -s "$dir$x"/"$configfile" |grep -v "grep"| awk '{ print "kill -9 "$2 }'|sh
			echo $server" -datadir="$dir$x"  -conf="$dir$x"/"$configfile" -pid="$dir$x"/"$pidfile" -reindex"|sh
			sleep $((30+i))

			getmasternode=$client" -conf="$dir$x"/"$configfile
			mnpk=$(echo ""|awk -v cli="$getmasternode" '{cli" masternode genkey"|getline ; print $0}')
			echo "Master Node Private Key: "$mnpk
			#echo "Wallet "$x" : "$(echo $client" -datadir="$dir$x"  -conf="$dir$x"/"$configfile" -pid="$dir$x"/"$pidfile" getaccountaddress mn1"|sh)

			echo "masternode=1" >> $dir$x"/"$configfile
			echo "masternodeprivkey="$mnpk >> $dir$x"/"$configfile

			echo "# Masternode config file" > $dir$x"/masternode.conf"
			echo "# Format: alias IP:port masternodeprivkey collateral_output_txid collateral_output_index" >> $dir$x"/masternode.conf"
			echo "# mn1 127.0.0.2:$port $mnpk 0 0" >> $dir$x"/masternode.conf"
		done
	fi

	echo
	echo Now deposit the collaterals in new wallets and edit the masternodes.conf files updating the TXID
	echo and restart the services.
	echo
	echo Enjoy.
	echo
	echo Example of restart service:
	echo
	echo   STOP
	echo     $client "-conf="${USERHOME}"/."$namemoney"001/"$configfile" stop"
	echo
	echo   START
	echo     $server "-conf="${USERHOME}"/."$namemoney"001/"$configfile" -datadir="${USERHOME}"/."$namemoney"001/ -pid="${USERHOME}"/."$namemoney"001/"$pidfile
fi

