#!/bin/bash

PREDATE=`grep "mysqli_real_connect" /var/log/apache2/error.log | cut -d"]" -f1 |  cut -d"[" -f2 | tail -n1`
DATE_APACHE=`date -d "$PREDATE"  +"%s"`
DATE_NOW=`date +%s`

DATE_DIFF_MINUTES = $[ ($DATE_NOW - $DATE_APACHE) / 60 ]

if [ "$DATE_DIFF_MINUTES" -gt 5 ]; then
    DO_ALERT=0
else
	DO_ALERT=1
fi

echo $DO_ALERT
