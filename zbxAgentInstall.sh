#!/bin/bash
#made by imort

pathScripts="/etc/zabbix/scripts"
hostname=`hostname`
pathConf="/etc/zabbix/zabbix_agentd.conf"
userParams="/etc/zabbix/zabbix_agentd.d/userparams.conf"
server=""

helpmenu()
{
        echo "         -h display helpmenu"
        echo "         Usage: -m | --with-mysql - install with mysql userparams"
        echo "                -a | --with-apache add ability to monitor apache"
	echo "		      -ng | --with-nginx add ability to monitor nginx"
        echo "                -n | --normal - install without any params"
}


NormalInstall()
{
        cd /root/
        wget http://repo.zabbix.com/zabbix/3.2/debian/pool/main/z/zabbix-release/zabbix-release_3.2-1+jessie_all.deb
        dpkg -i zabbix-release_3.2-1+jessie_all.deb
        apt-get update
        apt-get install zabbix-agent

	wget -O $pathScripts/ro-fs-test.sh http://zbx.sky-tours.com/scripts/ro-fs-test.sh

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
        NormalInstall
        cd $pathScripts
        wget http://zbx.sky-tours.com/scripts/mysql_status.sh >/dev/null 2>&1
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
                wget https://zbx.sky-tours.com/zabbix/scripts/nginx-check.sh
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
	cd /etc/zabbix/scripts/
	wget https://zbx.sky-tours.com/zabbix/scripts/zapache
	chown zabbix: zapache
	chmod +x zapache

}
while :
do
    case "$1" in
        -m | --with-mysql)
                WithMysql
                exit 0
                ;;
        -h | --help)
                helpmenu
                exit 0
                ;;
        -n | --normal)
                NormalInstall
                exit 0
                ;;
	-a | --with-apache)
		WithApache
		exit 0
		;;
	-ng | --with-nginx)
		WithNginx
		exit 0
		;;
        *)
                break
    esac
done

