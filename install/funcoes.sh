#!/bin/bash

# Copyright (C) 2014 CDR-port
# cdr-port@cdr-port.net

# Config Global
IFCONFIG=`which ifconfig 2>/dev/null||echo /sbin/ifconfig`
IPADDR=`$IFCONFIG eth0|gawk '/inet addr/{print $2}'|gawk -F: '{print $2}'`
INSTALL_DIR='/usr/share/cdrport'
CONFIG_DIR='/usr/share/cdrport/cdr-port'
BRANCH='master'
DB_PASSWORD=`</dev/urandom tr -dc A-Za-z0-9| (head -c $1 > /dev/null 2>&1 || head -c 20)`
echo "$DB_PASSWORD" > /usr/src/mysql_senha.txt


func_install_cdr-port () { 

				#Instalando CDR-port
				clear
				mkdir -p $INSTALL_DIR
				cd $INSTALL_DIR
				git clone -b $BRANCH https://github.com/skydrems/CDRPORT-INSTALL.git
				virtualenv --system-site-packages cdr-port
				cd cdr-port
				pip install -r $CONFIG_DIR/install/conf/requirements.txt
				sed -i "s/SENHA_DB/$DB_PASSWORD/" $CONFIG_DIR/install/conf/settings.txt
				cp $CONFIG_DIR/install/conf/settings.txt /usr/share/cdrport/cdr-port/cdrport/settings.py
				python manage.py syncdb
				python manage.py collectstatic --noinput

				cd $INSTALL_DIR/lib/python2.7/site-packages/registration/templates/
				rm -rf registration/

				wget -c https://github.com/skydrems/CDRPORT-INSTALL/raw/master/install/sql/base.sql.zip -O install/sql/base.sql.zip
				unzip $CONFIG_DIR/install/sql/base.sql.zip  -d $CONFIG_DIR/install/sql/
				mysql -u root -p"$DB_PASSWORD" cdrport < $CONFIG_DIR/install/sql/base.sql
				mysql -u root -p"$DB_PASSWORD" cdrport < $CONFIG_DIR/install/sql/rotinas.sql
				mysql -u root -p"$DB_PASSWORD" cdrport < $CONFIG_DIR/install/sql/views.sql
				#mysql -u root -p"$DB_PASSWORD" cdrport < $CONFIG_DIR/install/sql/portados.sql
				mysql -u root -p"$DB_PASSWORD" cdrport -e "ALTER TABLE cdr_cdr ALTER COLUMN portado SET DEFAULT 'Nao';"
				sed -i "s/SENHA_DB/$DB_PASSWORD/" $CONFIG_DIR/install/valida.py
				python $CONFIG_DIR/install/valida.py
				rm -rf $CONFIG_DIR/install/sql/base.sql.zip

				### Config nginx

				cp $CONFIG_DIR/install/conf/cdrport_nginx.conf /etc/nginx/sites-enabled/cdrport
				sed -i "s/127.0.0.1:8088/$IPADDR/" /etc/nginx/sites-enabled/cdrport
				/etc/init.d/nginx restart

				### FIM Config nginx

				#cp conf/my.cnf /etc/mysql/
				#/etc/init.d/mysql restart
				chmod +x $CONFIG_DIR/install/conf/cdrport.sh
				cp $CONFIG_DIR/install/conf/cdrport.sh /etc/init.d/
				#update-rc.d  cdrport.sh defaults
				cd $INSTALL_DIR
				chown -R www-data cdr-port
				/etc/init.d/cdrport.sh
				echo "/etc/init.d/cdrport.sh" >> /etc/rc.local
				ExitFinish=1
}


func_install_req_cdr-port () { 

				#Instalando dependências CDR-port
				clear
				#apt-get -y update
				#apt-get -y upgrade
				apt-get remove ajenti -y
				apt-get install build-essential  -y
				apt-get install python-virtualenv python-mysqldb python-dev python-imaging unzip git -y
				apt-get install nginx -y
				apt-get clean
				ExitFinish=1
}

func_install_mysql () { 

				#Instalando MySQL
				clear
				export DEBIAN_FRONTEND=noninteractive
				apt-get install -q -y mysql-server mysql-client libmysqlclient-dev -y
				echo "$DB_PASSWORD" > /usr/src/mysql_senha.txt
				mysqladmin -u root password "$DB_PASSWORD"
				mysql -u root -p"$DB_PASSWORD" -e "create database cdrport";
				ExitFinish=1
}

func_install_req_asterisk () { 

				#Instalando dependências Asterisk
				clear
				apt-get install -y  build-essential linux-headers-`uname -r` make bison flex  zip  curl sox  lshw ncurses-term\
				ttf-bitstream-vera libncurses5-dev automake libtool mpg123 sqlite3 libsqlite3-dev libncursesw5-dev uuid-dev\
				libxml2-dev libnewt-dev  pkg-config  autoconf subversion libltdl-dev libltdl7 libcurl3 libxml2-dev libiksemel-dev\
				libssl-dev libnewt-dev libusb-dev libeditline-dev libedit-dev libssl-dev libmysqlclient-dev libcurl4-gnutls-dev
				ExitFinish=1
}

func_install_asterisk () { 

				#Instalando ASTERISK
				clear
				rm -rf asterisk*
				cd /usr/src/
				wget -c http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-11.18.0.tar.gz
				tar zxvf asterisk-11.18.0.tar.gz
				ln -s asterisk-11.18.0 asterisk
				cd asterisk
				make distclean
				./configure
				contrib/scripts/get_mp3_source.sh
				make menuselect.makeopts
				menuselect/menuselect --disable CORE-SOUNDS-EN-GSM --enable app_mysql --enable cdr_mysql --enable res_config_mysql --enable  format_mp3 menuselect.makeopts
				make
				make install
				make config
				make samples
				ldconfig
            	cd ..
            	/etc/init.d/asterisk restart
            	ExitFinish=1                      
}

func_config_asterisk () { 

				#Instalando dependências Asterisk
				clear
				cd "$CONFIG_DIR"
            	sed -i "s/SENHA_DB/$DB_PASSWORD/" $CONFIG_DIR/install/conf/cdr_mysql.conf
            	cp -rfv $CONFIG_DIR/install/conf/cdr_mysql.conf /etc/asterisk/
            	ExitFinish=1
}
