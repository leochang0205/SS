#! /bin/bash
# Copyright (c) 2018 flyzy2005

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
usage () {
	cat $DIR/sshelp
}

wrong_para_prompt() {
    echo "Input argument error!$1"
}

install() {
	if [[ "$#" -lt 1 ]]
        then
          wrong_para_prompt "Please at least input one argument as password"
	  return 1
	fi
        port="1024"
        if [[ "$#" -ge 2 ]]
        then
          port=$2
        fi
        if [[ $port -le 0 || $port -gt 65535 ]]
        then
          wrong_para_prompt "Port No. format error, please input a number between 1~65535"
          exit 1
        fi
	echo "{
    \"server\":\"0.0.0.0\",
    \"server_port\":$port,
    \"local_address\": \"127.0.0.1\",
    \"local_port\":1080,
    \"password\":\"$1\",
    \"timeout\":300,
    \"method\":\"aes-256-cfb\"
}" > /etc/shadowsocks.json
	apt-get update
	apt-get install -y python-pip
	pip install --upgrade pip
	pip install setuptools
	pip install shadowsocks
	chmod 755 /etc/shadowsocks.json
	apt-get install python-m2crypto
	ps -fe|grep ssserver |grep -v grep > /dev/null 2>&1
        if [ $? -ne 0 ]
        then
          ssserver -c /etc/shadowsocks.json -d start
        else
          ssserver -c /etc/shadowsocks.json -d restart
        fi
	rclocal=`cat /etc/rc.local`
        if [[ $rclocal != *'ssserver -c /etc/shadowsocks.json -d start'* ]]
        then
          sed -i '$i\ssserver -c /etc/shadowsocks.json -d start'  /etc/rc.local
        fi
	echo "Install successful, enjoy it
Your configuration content as below :"
	cat /etc/shadowsocks.json
}

install_bbr() {
	sysfile=`cat /etc/sysctl.conf`
	if [[ $sysfile != *'net.core.default_qdisc=fq'* ]]
	then
    		echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	fi
	if [[ $sysfile != *'net.ipv4.tcp_congestion_control=bbr'* ]]
	then
    		echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	fi
	sysctl -p > /dev/null
	i=`uname -r | cut -f 2 -d .`
	if [ $i -le 9 ]
	then
    		if
        	echo 'prepare for download image file...' && wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.2/linux-image-4.10.2-041002-generic_4.10.2-041002.201703120131_amd64.deb
    		then
        		echo 'image file download successful，start instaling...' && dpkg -i linux-image-4.10.2-041002-generic_4.10.2-041002.201703120131_amd64.deb && update-grub && echo 'image file install successful，system will be restart，after restart bbr will be start successful...' && reboot
    		else
        		echo 'download faild, please re-execute install BBR command'
        		exit 1
    		fi
	fi
	result=`sysctl net.ipv4.tcp_available_congestion_control`
	if [[ $result == *'bbr'* ]]
	then
    		echo 'BBR start successful'
	else 
    		echo 'BBR start faild，please re-execute'
	fi
}

install_ssr() {
	wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR.sh
	chmod +x shadowsocksR.sh
	./shadowsocksR.sh 2>&1 | tee shadowsocksR.log
}

uninstall_ss() {
	ps -fe|grep ssserver |grep -v grep > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
          ssserver -c /etc/shadowsocks.json -d stop
        fi
	pip uninstall -y shadowsocks
	rm /etc/shadowsocks.json
	rm /var/log/shadowsocks.log
	echo 'shadowsocks uninstalled'
}

if [ "$#" -eq 0 ]; then
	usage
	exit 0
fi

case $1 in
	-h|h|help )
		usage
		exit 0;
		;;
	-v|v|version )
		echo 'ss-leo Version 1.0, 2018-01-20, Copyright (c) 2018 flyzy2005'
		exit 0;
		;;
esac

if [ "$EUID" -ne 0 ]; then
	echo 'root id needed, please try sudo command'
	exit 1;
fi

case $1 in
	-i|i|install )
        install $2 $3
		;;
        -bbr )
        install_bbr
                ;;
        -ssr )
        install_ssr
                ;;
	-uninstall )
	uninstall_ss
		;;
	* )
		usage
		;;
esac
