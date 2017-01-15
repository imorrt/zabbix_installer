#!/bin/bash

cd /etc/zabbix/scripts/
wget https://raw.githubusercontent.com/imorrt/zabbix_installer/master/segmentation_fault_check.sh
chmod +x segmentation_fault_check.sh
chown zabbix:zabbix segmentation_fault_check.sh
echo "UserParameter=segfault,/etc/zabbix/scripts/segmentation_fault_check.sh" >> /etc/zabbix/zabbix_agentd.d/userparams.conf
/etc/init.d/zabbix-agent stop
/etc/init.d/zabbix-agent start
