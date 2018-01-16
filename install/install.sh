#!/bin/bash

# Copyright (C) 2014 CDR-port
# cdr-port@cdr-port.net

# Configurar o Branch
BRANCH='master'

apt-get update -y
apt-get upgrade -y
apt-get -y install lsb-release gawk

#Instala o menu
mkdir /etc/asterisk
cd /usr/src/
wget --no-check-certificate  https://raw.githubusercontent.com/skydrems/CDRPORT-INSTALL$BRANCH/install/funcoes.sh
wget --no-check-certificate  https://raw.githubusercontent.com/skydrems/CDRPORT-INSTALL$BRANCH/install/menu.sh
bash menu.sh

