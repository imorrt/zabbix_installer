#!/bin/bash
#created by imort

pathScripts="/etc/zabbix/scripts"
hostname=`hostname`
pathConf="/etc/zabbix/zabbix_agentd.conf"
checkOS=`cat /etc/issue | awk '{print $3}'`
if [[ $checkOS = "8" ]]; then
    userParams="/etc/zabbix/zabbix_agentd.d/userparams.conf"
elif [[ $checkOS = "9" ]]; then
    userParams="/etc/zabbix/zabbix_agentd.conf.d/userparams.conf"
fi
repo="https://raw.githubusercontent.com/imorrt/zabbix_installer/master"

helpmenu()
{
        echo "         -h display helpmenu"
        echo "         Usage: -m | --mysql - install with mysql userparams"
        echo "                -a | --apache add ability to monitor apache"
        echo "                -n | --nginx add ability to monitor nginx"
        echo "                -i | --install - install without any params"
        echo "                -p | --php5-fpm - add ability to monitor php5-fpm"
        echo "                -P | --php-fpm7 - add ability to monitor php7-fpm"
        echo "                -e | --elasticSearch - add ability to monitor ElasticSearch Cluster or Node"
        echo "                -r | --rabbitmq - add ability to monitor RabbitMQ"      
        echo "                -x | --postfix - add ability to monitor postfix queue"
}


Install()
{
        echo -n "Please enter ip of your zabbix server: "
        read server

        if [[ $checkOS = "8" ]]; then
            cd /root/
            wget http://repo.zabbix.com/zabbix/3.2/debian/pool/main/z/zabbix-release/zabbix-release_3.2-1+jessie_all.deb
            dpkg -i zabbix-release_3.2-1+jessie_all.deb
            apt-get update
            apt-get install zabbix-agent -y

        elif [[ $checkOS = "9" ]]; then
            apt-get update
            apt-get install zabbix-agent -y
        else
            exit
        fi       


        
        hashIdentity=`openssl rand -hex 16`
        openssl rand -hex 32 > /etc/zabbix/zabbix_agent.psk
        psk=`cat /etc/zabbix/zabbix_agent.psk`

        mkdir /etc/zabbix/scripts
        chown zabbix:zabbix $pathScripts

        echo -n > $pathConf
        echo "PidFile=/var/run/zabbix/zabbix_agentd.pid" >> $pathConf
        if [[ $checkOS = "8" ]]; then
            echo "LogFile=/var/log/zabbix/zabbix_agentd.log" >> $pathConf
        elif [[ $checkOS = "9" ]]; then
            echo "LogFile=/var/log/zabbix-agent/zabbix_agentd.log" >> $pathConf
        fi
        echo "EnableRemoteCommands=1" >> $pathConf
        echo "Server=$server" >> $pathConf
        echo "Timeout=30" >> $pathConf
        echo "Hostname=$hostname" >> $pathConf
        echo "AllowRoot=1" >> $pathConf
        echo "UnsafeUserParameters=1" >> $pathConf
        echo "TLSConnect=psk" >> $pathConf
        echo "TLSAccept=psk" >> $pathConf
        echo "TLSPSKFile=/etc/zabbix/zabbix_agent.psk" >> $pathConf
        echo "TLSPSKIdentity=$hashIdentity" >> $pathConf
        echo "Include=$userParams" >> $pathConf
        touch $userParams

        cd $pathScripts
        wget $repo/ro-fs-test.sh
        chmod +x ro-fs-test.sh
        chown zabbix:zabbix ro-fs-test.sh
        
        echo "UserParameter=readonlyfs,/etc/zabbix/scripts/ro-fs-test.sh" >> $userParams
        echo "UserParameter=apt.security,apt-get -s upgrade | grep -ci ^inst.*security" >> $userParams
        echo "UserParameter=apt.updates,apt-get -s upgrade | grep -iPc '^Inst((?!security).)*$'" >> $userParams
        echo "APT::Periodic::Enable \"1\";" >> /etc/apt/apt.conf.d/02periodic
        echo "APT::Periodic::Update-Package-Lists \"1\";"  >> /etc/apt/apt.conf.d/02periodic
        
        /etc/init.d/zabbix-agent stop
        /etc/init.d/zabbix-agent start

        echo
        echo -ne "Path to config: $pathConf\n"
        echo -ne "FOR ZABBIX SERVER\n"
        echo -ne "PSK Identity = $hashIdentity\n"
        echo -ne "PSK = $psk\n"
        update-rc.d zabbix-agent defaults
        systemctl enable zabbix-agent
}

Postfix()
{
    echo "UserParameter=postfix.queue,   mailq | awk '/Request./ {print \$5}'" >> $userParams
    echo 'UserParameter=postfix.maildrop,find /var/spool/postfix/maildrop -type f | wc -l' >> $userParams
    echo 'UserParameter=postfix.deferred,find /var/spool/postfix/deferred -type f | wc -l' >> $userParams
    echo 'UserParameter=postfix.incoming,find /var/spool/postfix/incoming -type f | wc -l' >> $userParams
    echo 'UserParameter=postfix.active,  find /var/spool/postfix/active -type f | wc -l' >> $userParams
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start

}

RabbitMQ()
{
    cd $pathScripts
    wget $repo/detect_rabbitmq_nodes.sh >/dev/null 2>&1
    echo 'UserParameter=rabbitmq.discovery,/etc/zabbix/scripts/detect_rabbitmq_nodes.sh' >> $userParams
    echo 'UserParameter=rabbitmq.discovery_queue,/etc/zabbix/scripts/detect_rabbitmq_nodes.sh queue' >> $userParams
    echo 'UserParameter=rabbitmq.discovery_exchanges,/etc/zabbix/scripts/detect_rabbitmq_nodes.sh exchange' >> $userParams
    echo 'UserParameter=rabbitmq[*],/etc/zabbix/scripts/rabbitmq-status.sh $1 $2 $3 $4' >> $userParams
    chown zabbix:zabbix detect_rabbitmq_nodes.sh
    chmod +x detect_rabbitmq_nodes.sh
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}
WithMysql()
{
    cd $pathScripts
    wget $repo/mysql_status.sh >/dev/null 2>&1
    echo 'UserParameter=mysql.status[*],/etc/zabbix/scripts/mysql_status.sh $1' >> $userParams
    echo 'UserParameter=mysql.ping,/etc/zabbix/scripts/mysql_status.sh Ping' >> $userParams
    echo 'UserParameter=mysql.version,/etc/zabbix/scripts/mysql_status.sh Version' >> $userParams
    chown zabbix:zabbix mysql_status.sh
    chmod +x mysql_status.sh
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}



WithNginx()
{
        check=`nginx -V 2>&1 | grep -c with-http_stub_status_module`
        if [ "$check" -eq "1" ]; then
                cd /etc/zabbix/scripts
                wget $repo/nginx-check.sh
        chown zabbix:zabbix nginx-check.sh
        chmod +x nginx-check.sh
                echo 'UserParameter=nginx[*],/etc/zabbix/scripts/nginx-check.sh "$1" "$2"' >> $userParams
cat << EOF > /etc/nginx/conf.d/nginx_status.conf
server {
        listen 10061;
        location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
        }
}
EOF
        /etc/init.d/nginx reload
        else
                echo 'OOOOOOPS!! Nginx configured without with-http_stub_status_module. Installation aborted'
        fi
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start  
}


WithApache()
{
    a2enmod status
cat << EOF > /etc/apache2/mods-available/status.conf
<IfModule mod_status.c>
    Listen 8001
    ExtendedStatus On 
    <Location /server-status>
            SetHandler server-status
            Allow from 127.0.0.1 ::1
            Order deny,allow
            Deny from all
    </Location>
    ExtendedStatus On
        <IfModule mod_proxy.c>
                ProxyStatus On
        </IfModule>
</IfModule>
EOF

    echo 'UserParameter=apache[*],/etc/zabbix/scripts/zapache $1' >> $userParams

    /etc/init.d/apache2 restart
    cd $pathScripts
    wget $repo/zapache
    chown zabbix: zapache
    chmod +x zapache
    
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}

WithPhp5-fpm()
{
    cd $pathScripts
    wget $repo/php-fpm.sh > /dev/null 2>&1
    chmod +x php-fpm.sh
    chown zabbix:zabbix php-fpm.sh
    sed -i -e 's/\r$//' $pathScripts/php-fpm.sh
    
    echo 'UserParameter=php-fpm.status[*],/etc/zabbix/scripts/php-fpm.sh $1' >> $userParams
    
    sed -i "s/;pm.status_path/pm.status_path/" /etc/php5/fpm/pool.d/www.conf
    sed -i "s/;ping/ping/" /etc/php5/fpm/pool.d/www.conf
    /etc/init.d/php5-fpm reload 
cat << EOF > /etc/nginx/conf.d/php-fpm-status.conf
server {
    listen 80;
    listen [::]:80;
    server_name  localhost;
        location ~ ^/(status|ping)$ {
                access_log off;
                allow 127.0.0.1;
                allow ::1;
                deny all;
                include fastcgi_params;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
}
EOF
    /etc/init.d/nginx reload
    test=`curl -s http://localhost/status | grep -c pool`
    if [ "$test" -eq 1 ];then
        echo "Template for php5-fpm monitor successfull installed"
    else
        echo "SOMETHING WRONG WITH php5-fpm!!"
    fi

    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}


WithPhp-fpm7()
{
    cd $pathScripts
    wget $repo/php-fpm.sh > /dev/null 2>&1
    chmod +x php-fpm.sh
    chown zabbix:zabbix php-fpm.sh
    sed -i -e 's/\r$//' $pathScripts/php-fpm.sh
    
    echo 'UserParameter=php-fpm.status[*],/etc/zabbix/scripts/php-fpm.sh $1' >> $userParams
    
    sed -i "s/;pm.status_path/pm.status_path/" /etc/php/7.0/fpm/pool.d/www.conf
    sed -i "s/;ping/ping/" /etc/php/7.0/fpm/pool.d/www.conf
    /etc/init.d/php7.0-fpm reload 
cat << EOF > /etc/nginx/conf.d/php-fpm-status.conf
server {
    listen 80;
    listen [::]:80;
    server_name  localhost;
        location ~ ^/(status|ping)$ {
                access_log off;
                allow 127.0.0.1;
                allow ::1;
                deny all;
                include fastcgi_params;
                fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }
}
EOF
    /etc/init.d/nginx reload
    test=`curl -s http://localhost/status | grep -c pool`
    if [ "$test" -eq 1 ];then
        echo "Template for php-fpm7.0 monitor successfull installed"
    else
        echo "SOMETHING WRONG WITH php-fpm7.0!!"
    fi

    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}

WithElasticsearch()
{
    cd $pathScripts
    wget $repo/elasticsearch.sh
    chmod +x elasticsearch.sh
    chown zabbix:zabbix elasticsearch.sh
    echo 'UserParameter=es[*],/etc/zabbix/scripts/elasticsearch.sh $1' >> $userParams
    
    /etc/init.d/zabbix-agent stop
    /etc/init.d/zabbix-agent start
}


PARSED_OPTIONS=$(getopt -n "$0"  -o hinampePrx --long "help,install,nginx,apache,mysql,php5-fpm,elasticSearch,php-fpm7,rabbitmq,postfix"  -- "$@")
if [ $? -ne 0 ];
then
  exit 1
fi
eval set -- "$PARSED_OPTIONS"
while true;
do
  case "$1" in
 
    -h|--help)
      helpmenu
      shift;;
      
    -e|--elasticSearch)
      WithElasticsearch
      shift;;
        
    -m|--mysql)
      WithMysql
      shift;;
 
    -n|--nginx)
      WithNginx
      shift;;
    
    -a|--apache)
      WithApache
      shift;;

    -p|--php5-fpm)
      WithPhp5-fpm
      shift;;
      
    -P|--php-fpm7)
      WithPhp-fpm7
      shift;;
            
    -r|--rabbitmq)
      RabbitMQ
      shift;;
            
    -x|--postfix)
      Postfix
      shift;;

    -i|--install)
      Install
      shift;;
    --)
      shift
      break;;
  esac
done
