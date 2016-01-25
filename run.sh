#!/bin/bash

# temp. start mysql to do all the install stuff
/usr/bin/mysqld_safe > /dev/null 2>&1 &

# ensure mysql is running properly
sleep 20 

# install pimcore if needed
if [ ! -d /var/www/pimcore ]; then
  # download & extract
  cd /var/www
  rm -r /var/www/*
  sudo -u www-data wget https://www.pimcore.org/download/pimcore-data.zip -O /tmp/pimcore.zip 
  sudo -u www-data unzip /tmp/pimcore.zip -d /var/www/
  rm /tmp/pimcore.zip 
  
  # create demo mysql user
  mysql -u root -e "CREATE USER 'pimcore_LEGO'@'%' IDENTIFIED BY 'secretpassword';"
  mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'pimcore_LEGO'@'%' WITH GRANT OPTION;"
  
  # setup database 
  mysql -u pimcore_LEGO -psecretpassword -e "CREATE DATABASE pimcore_demo_pimcore charset=utf8;"; 
  mysql -u pimcore_LEGO -psecretpassword pimcore_LEGO_pimcore < /var/www/pimcore/modules/install/mysql/install.sql
  mysql -u pimcore_LEGO -psecretpassword pimcore_LEGO_pimcore < /var/www/website/dump/data.sql
  
  # 'admin' password is 'demo' 
  mysql -u pimcore_LEGO -psecretpassword -D pimcore_LEGO_pimcore -e "UPDATE users SET password = '\$2y\$10\$P8w92BSI2qp4q0VHUFe9nutv0A3MGhnyr.e43p4hfhrfcy1zZqyMO' WHERE name = 'admin'"  
  mysql -u pimcore_LEGO -psecretpassword -D pimcore_LEGO_pimcore -e "UPDATE users SET id = '0' WHERE name = 'system'"
  
  sudo -u www-data mv /var/www/website/var/config/system.xml.template /var/www/website/var/config/system.xml
  sudo -u www-data cp /tmp/cache.xml /var/www/website/var/config/cache.xml
fi

# stop temp. mysql service
mysqladmin -uroot shutdown

exec supervisord -n


