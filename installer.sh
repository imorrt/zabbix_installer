#!/bin/bash
#made by imort

pathScripts="/etc/zabbix/scripts"
hostname=`hostname`
pathConf="/etc/zabbix/zabbix_agentd.conf"
userParams="/etc/zabbix/zabbix_agentd.d/userparams.conf"
repo="https://raw.githubusercontent.com/imorrt/zabbix_installer/master"

helpmenu()
{
        echo "         -h display helpmenu"
        echo "         Usage: -m | --mysql - install with mysql userparams"
        echo "                -a | --apache add ability to monitor apache"
	echo "		      -n | --nginx add ability to monitor nginx"
        echo "                -i | --install - install without any params"
	echo "		      -p | --php5-fpm - add ability to monitor php5-fpm"
}


Install()
{
		echo -n "Please enter ip of your zabbix server: "
		read server
				
		cd /root/
		wget http://repo.zabbix.com/zabbix/3.2/debian/pool/main/z/zabbix-release/zabbix-release_3.2-1+jessie_all.deb
		dpkg -i zabbix-release_3.2-1+jessie_all.deb
		apt-get update
		apt-get install zabbix-agent

	wget -O $pathScripts/ro-fs-test.sh $repo/ro-fs-test.sh

		hashIdentity=`openssl rand -hex 16`
		openssl rand -hex 32 > /etc/zabbix/zabbix_agent.psk
		psk=`cat /etc/zabbix/zabbix_agent.psk`

		mkdir /etc/zabbix/scripts
		chown zabbix:zabbix $pathScripts

		echo -n > $pathConf
		echo "PidFile=/var/run/zabbix/zabbix_agentd.pid" >> $pathConf
		echo "LogFile=/var/log/zabbix/zabbix_agentd.log" >> $pathConf
		echo "EnableRemoteCommands=1" >> $pathConf
		echo "Server=$server" >> $pathConf
		echo "Hostname=$hostname" >> $pathConf
		echo "AllowRoot=1" >> $pathConf
		echo "UnsafeUserParameters=1" >> $pathConf
		echo "TLSConnect=psk" >> $pathConf
		echo "TLSAccept=psk" >> $pathConf
		echo "TLSPSKFile=/etc/zabbix/zabbix_agent.psk" >> $pathConf
		echo "TLSPSKIdentity=$hashIdentity" >> $pathConf
		echo "Include=$userParams" >> $pathConf
	touch $userParams


	echo "UserParameter=readonlyfs,/etc/zabbix/scripts/ro-fs-test.sh" >> $userParams

	/etc/init.d/zabbix-agent restart
	/etc/init.d/zabbix-agent restart

		echo
		echo -ne "Path to config: $pathConf\n"
		echo -ne "FOR ZABBIX SERVER\n"
		echo -ne "PSK Identity = $hashIdentity\n"
		echo -ne "PSK = $psk\n"
		
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
        /etc/init.d/nginx restart
        else
                echo 'OOOOOOPS!! Nginx configured without with-http_stub_status_module. Installation aborted'
        fi
}


WithApache()
{
	a2enmod status
cat << EOF > /etc/apache2/mods-available/status.conf
<IfModule mod_status.c>	
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

}

WithPhp5-fpm()
{
	cd $pathScripts
	wget $repo/php-fpm.sh > /dev/null 2>&1
	chmod +x php-fpm.sh
	chown zabbix:zabbix php-fpm.sh
	
	echo 'UserParameter=php-fpm.status[*],/etc/zabbix/scripts/php-fpm.sh $1' >> $userParams
	
	sed -i "s/;pm.status_path/pm.status_path/" /etc/php5/fpm/pool.d/www.conf
	sed -i "s/;ping/ping/" /etc/php5/fpm/pool.d/www.conf
	/etc/init.d/php5-fpm restart 
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
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
}
EOF
	/etc/init.d/nginx restart
	test=`curl -s http://localhost/status | grep -c pool`
	if [ "$test" -eq 1 ];then
		echo "Template for php5-fpm monitor successfull installed"
	else
		echo "SOMETHING WRONG WITH php5-fpm!!"
	fi

}

PARSED_OPTIONS=$(getopt -n "$0"  -o hinamp --long "help,install,nginx,apache,mysql,php5-fpm"  -- "$@")
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
 
    -i|--mysql)
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
	  
    -i|--install)
      Install
	  shift;;
#      if [ -n "$2" ];
#      then
#        echo "You need to paste zabbix server ip after --install"
#      fi
#      shift 2;;
 
    --)
      shift
      break;;
  esac
done
