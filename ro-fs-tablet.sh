#!/bin/bash
#made by imort

pathScripts="/etc/zabbix/scripts"
userParams="/etc/zabbix/zabbix_agentd.d/userparams.conf"
repo="https://raw.githubusercontent.com/imorrt/zabbix_installer/master"

check=`grep -c readonlyfs /etc/zabbix/zabbix_agentd.d/userparams.conf`
if [ "$check" -eq 0 ];
then
	wget -O $pathScripts/ro-fs-test.sh $repo/ro-fs-test.sh > /dev/null 2>&1
	echo "UserParameter=readonlyfs,/etc/zabbix/scripts/ro-fs-test.sh" >> $userParams
	/etc/init.d/zabbix-agent stop
	/etc/init.d/zabbix-agent start
	echo "COMPLETE"
	
else
	echo "ro-fs-test already installed"
fi