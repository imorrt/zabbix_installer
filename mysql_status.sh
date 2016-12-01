#!/bin/bash

Mysql='/usr/bin/mysql --defaults-file=/root/.my.cnf'
Mysqladmin='/usr/bin/mysqladmin --defaults-file=/root/.my.cnf'

command(){
   $Mysql -e "show global status" | awk '$1 ~ /'"$1"'$/ {print $2}'
}

replication_check(){
   $Mysql -E -e "show slave status;" | grep "$1" | sed -e 's/.*: //g'
}

case $1 in
  Seconds_Behind_Master)
    replication_check $1 ;;
  Com_select)
    command $1 ;;
  Com_insert)
    command $1 ;;
  Com_update)
    command $1 ;;
  Com_delete)
    command $1 ;;
  Com_begin)
    command $1 ;;
  Com_commit)
    command $1 ;;
  Com_rollback)
    command $1 ;;
  Questions)
    command $1 ;;
  Slow_queries)
    command $1 ;;
  Bytes_received)
    command $1 ;;
  Bytes_sent)
    command $1 ;;
  Uptime)
    command $1 ;;
  Version)
    $Mysql -V | awk -F '[ ,]' '{print $6}' ;;
  Ping)
    $Mysqladmin ping | wc -l ;;
  *)
    echo "You asked for $1 - not supported;"
    echo "Usage: $0 { Seconds_Behind_Master|Com_select|Com_insert|Com_update|Com_delete|Com_begin|Com_commit|Com_rollback|Questions|Slow_queries|Bytes_received|Bytes_sent|Ping|Uptime|Version }" ;;
esac
