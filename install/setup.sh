#!/bin/bash

# Copyright (C) 2014 CDR-port
# cdr-port@cdr-port.net
# GLOBAL
source funcoes.sh
IFCONFIG=`which ifconfig 2>/dev/null||echo /sbin/ifconfig`
IPADDR=`$IFCONFIG eth0|gawk '/inet addr/{print $2}'|gawk -F: '{print $2}'`
INSTALL_DIR='/usr/share/cdrport'
DB_PASSWORD=`</dev/urandom tr -dc A-Za-z0-9| (head -c $1 > /dev/null 2>&1 || head -c 20)`

# FIM GLOBAL

apt-get -y update
apt-get -y upgrade
apt-get remove ajenti -y
apt-get install build-essential  -y
apt-get install python-virtualenv python-mysqldb python-dev python-imaging unzip git -y
apt-get install nginx -y
apt-get clean

### MySQL install
export DEBIAN_FRONTEND=noninteractive
apt-get install -q -y mysql-server mysql-client libmysqlclient-dev -y
echo "$DB_PASSWORD" > /usr/src/mysql_senha.txt
mysqladmin -u root password "$DB_PASSWORD"
mysql -u root -p"$DB_PASSWORD" -e "create database cdrport";
### FIM MySQL install



### Virtualenvs

mkdir -p /usr/share/cdrport
cd /usr/share/cdrport
git clone -b master https://github.com/skydrems/CDRPORT-INSTALL.git
virtualenv --system-site-packages cdr-port
cd cdr-port
pip install -r install/requirements.txt
sed -i "s/SENHA_DB/$DB_PASSWORD/" install/settings.txt
cp install/settings.txt /usr/share/cdrport/cdr-port/cdrport/settings.py
python manage.py syncdb --noinput
python manage.py collectstatic --noinput

wget -c https://github.com/skydrems/CDRPORT-INSTALL/raw/master/install/sql/base.sql.zip -O install/sql/base.sql.zip
unzip install/sql/base.sql.zip  -d install/sql/
mysql -u root -p"$DB_PASSWORD" cdrport < install/sql/base.sql
mysql -u root -p"$DB_PASSWORD" cdrport < install/sql/rotinas.sql
mysql -u root -p"$DB_PASSWORD" cdrport < install/sql/views.sql
mysql -u root -p"$DB_PASSWORD" cdrport < install/sql/portados.sql
rm -rf install/sql/base.sql.zip

### Config nginx

cp install/cdrport_nginx.conf /etc/nginx/sites-enabled/cdrport
sed -i "s/127.0.0.1:8088/$IPADDR/" /etc/nginx/sites-enabled/cdrport
/etc/init.d/nginx restart

### FIM Config nginx

#cp install/my.cnf /etc/mysql/
#/etc/init.d/mysql restart
chmod +x install/gunicorn_launcher.sh
cp install/gunicorn_launcher.sh /etc/init.d/
update-rc.d  gunicorn_launcher.sh defaults
cd /usr/share/cdrport
chown -R www-data cdr-port
/etc/init.d/gunicorn_launcher.sh
echo "/etc/init.d/gunicorn_launcher.sh" >> /etc/rc.local

###
