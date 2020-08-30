#!/bin/sh
V2DIR=.
V2CONF=${V2DIR}/config.json

#echo "Load modprobe"
modprobe ip_set_hash_net
modprobe xt_set

cd ${V2DIR}
sh stop.sh

#echo "[cleanning iptables]"
iptables -t nat -D PREROUTING V2RAY  >/dev/null 2>&1
iptables -t nat -D OUTPUT V2RAY  >/dev/null 2>&1
/bin/iptables -t nat -F V2RAY >/dev/null 2>&1
/bin/iptables -t nat -X V2RAY >/dev/null 2>&1
/sbin/ipset destroy chnroute >/dev/null 2>&1
#echo "ipset chnroute"
ipset -exist create chnroute hash:net hashsize 64
sed -e "s/^/add chnroute /" ${V2DIR}/chnroute.txt | ipset restore
echo "[setting iptables]"
iptables -t nat -N V2RAY
iptables -t nat -A V2RAY -d 0.0.0.0 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.1 -j RETURN
iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A V2RAY -m set --match-set chnroute dst -j RETURN
# Anything else should be redirected to Dokodemo-door's local port
iptables -t nat -A V2RAY -p tcp --dport 22:500 -j REDIRECT --to-ports 1234
#iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 1234
iptables -t nat -A PREROUTING -p tcp -j V2RAY


echo "-----------------[V2Ray started]---------------------------"
echo ""
echo "#stop v2ray"
echo "[sh ${V2DIR}/stop.sh]"
echo ""
echo "#Autoruns:"
echo "[ /usr/v2/start.sh & ]"
echo ""
echo "#USE 5353 DNS FOR GFWLIST:"
echo "#Custom 'dnsmasq.conf'"
echo "conf-dir=/usr/v2/dnsmasq-gwlist/, *.hosts "
echo ""
echo "-------------you can close this Window---------------------"


cd ${V2DIR}
CONFURL="$(nvram get v2_config_url)"
CONFTMP="$(nvram get v2_config_tmp)"

if [ -n "${CONFTMP}" ]; then
	V2CONF=/tmp/config.json
	logger -st "V2" "Using /tmp/config.json as config file."
elif [ -n "${CONFURL}" ]; then
	logger -st "V2" "Starting download v2 config file..."
	rm /tmp/v2-config.json
	curl -k -s -o /tmp/v2-config.json --connect-timeout 10 --retry 3 ${CONFURL}
	if [ $? -eq 0 ]; then
		V2CONF=/tmp/v2-config.json
	else
		logger -st "V2" "download config file failed, using default config file."
	fi
fi

ulimit -n 10240
./v2ray --config=${V2CONF} >/dev/null 2>&1 &
logger -st "V2" "V2 started."
./v2ray-watchdog >/dev/null 2>&1 &

