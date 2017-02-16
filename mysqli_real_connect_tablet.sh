#!/bin/bash
cd /etc/zabbix/scripts/
wget https://raw.githubusercontent.com/imorrt/zabbix_installer/master/mysqli_real_connect.sh
chmod +x mysqli_real_connect.sh
chown zabbix:zabbix mysqli_real_connect.sh
echo "UserParameter=mrcon,/etc/zabbix/scripts/mysqli_real_connect.sh" >> /etc/zabbix/zabbix_agentd.d/userparams.conf


/etc/init.d/zabbix-agent stop
/etc/init.d/zabbix-agent start
