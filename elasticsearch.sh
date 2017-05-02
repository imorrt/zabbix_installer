#!/bin/bash

HOST=""

ClusterHealth(){
CHECK=`curl -s -XGET 'http://${HOST}:9200/_cluster/health?pretty=true' | grep status | awk '{print $3}' | cut -d"\"" -f2`
if [[ "$CHECK" = "yellow" ]]; then
	echo "1"
elif [[ "$CHECK" = "red" ]]; then
	echo "2"
else 
	echo "0"
fi
}

Unassigned(){
curl -s -XGET 'http://${HOST}:9200/_cat/shards?v' | grep -c UNASSIGNED
}

case $1 in
  ClusterHealth)
    ClusterHealth;;
  Unassigned)
    Unassigned;;
  *)
    echo "You asked for $1 - not supported;"
    echo "Usage: $0 { ClusterHealth | Unassigned }" ;;
esac

