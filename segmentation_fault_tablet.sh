#!/bin/bash
cd /etc/zabbix/scripts/
wget https://raw.githubusercontent.com/imorrt/zabbix_installer/master/segmentation_fault_check.sh
sed -i -e 's/\r$//' segmentation_fault_check.sh
chmod +x segmentation_fault_check.sh
chown zabbix:zabbix segmentation_fault_check.sh
echo "UserParameter=segfault,/etc/zabbix/scripts/segmentation_fault_check.sh" >> /etc/zabbix/zabbix_agentd.d/userparams.conf
