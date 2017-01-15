#!/bin/bash

DATE_APACHE=`grep "Segmentation fault" /var/log/apache2/error.log | cut -d"]" -f1 |  cut -d"[" -f2 | tail -n1`
DATE_NOW=`date +%s`

DATE_DIFF_MINUTES = $[ ($DATE_NOW - $DATE_APACHE) / 60 ]

if [ $DATE_DIFF_MINUTES -gt 15 ]; then
    DO_ALERT=0
else
	DO_ALERT=1
fi

echo $DO_ALERT
