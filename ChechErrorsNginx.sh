#!/bin/bash

NginxLog="/var/log/nginx/access.log"
REQ="$1"

DATE_NOW=`date +"%s"`
PREDATE=`grep $REQ $NginxLog | awk '{print $4}' |cut -d"[" -f2 | sed  "s/\// /g" | sed "s/:/ /"`
DATE_NGINX=`date -d "$PREDATE"  +"%s"`
CHECK=$[ ($DATE_NOW - $DATE_NGINX) / 60 ]
if [ $CHECK -gt 2 ]; then
	DO_ALERT=0
else
	DO_ALERT=1
fi
echo $DO_ALERT
