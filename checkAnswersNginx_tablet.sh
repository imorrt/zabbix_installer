#!/bin/bash

cd /etc/zabbix/scripts/
wget https://raw.githubusercontent.com/imorrt/zabbix_installer/master/ChechErrorsNginx.sh
chown zabbix:zabbix ChechErrorsNginx.sh
chmod +x ChechErrorsNginx.sh
echo 'UserParameter=NginxErrorCode[*],/etc/zabbix/scripts/ChechErrorsNginx.sh $1' >> /etc/zabbix/zabbix_agentd.d/userparams.conf
