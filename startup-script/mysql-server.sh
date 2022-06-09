#!/bin/bash
#Creating swapfile 
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -qxF "/swapfile swap swap defaults 0 0" /etc/fstab || echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

#Update repo and install
apt-get update -q
apt-get -y  install wget nano mysql-server git -q

#Allow mysql to be accesible outside
sed -i "s|127.0.0.1|0.0.0.0|g" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

#Create Mysql user and database
mysql -e "CREATE DATABASE thrifthunter;"
mysql -e "CREATE USER 'thrift'@'10.240.0.7/255.255.240.0' IDENTIFIED BY 'hhrifttunter';"
mysql -e "GRANT ALL PRIVILEGES ON thrifthunter.* TO 'thrift'@'%';"


#Pull database DDL and DML
git clone https://github.com/thrifthunter/dbms /root/dbms
mysql -D thrifthunter < /root/dbms/ddl/.all_files.sql

#Creating variable
DISK_LOCATION="/dev/sdb"
MOUNT_POINT="/media/data"
UUID=$(blkid | grep -oE "/dev/sdb: UUID=\".*\" " | grep -oE "\".*\"")

mkfs -t ext4 $DISK_LOCATION
mkdir $MOUNT_POINT
mount $DISK_LOCATION $MOUNT_POINT
grep -qxF "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" /etc/fstab || echo "UUID=$UUID $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab 
systemctl stop mysql 
mv /var/lib/mysql/ $MOUNT_POINT/.

DATADIR="datadir = $MOUNT_POINT/mysql"
LOGBIN="log_bin = $MOUNT_POINT/mysql/mysql-bin.log"
FILEPATH="/etc/mysql/mysql.conf.d/mysqld.cnf"
grep -qxF "$DATADIR"  $FILEPATH || echo "$DATADIR" >> $FILEPATH
grep -qxF "$LOGBIN"  $FILEPATH || echo "$LOGBIN" >> $FILEPATH
sed -i "s|log_error = /var/log/mysql/error.log|log_error =/media/data/mysql/error.log|g" $FILEPATH

sed -i "s|/var/lib/mysql/|$MOUNT_POINT/mysql/|g"  /etc/apparmor.d/usr.sbin.mysqld
grep -qxF "alias /var/lib/mysql/ -> $MOUNT_POINT/mysql/," /etc/apparmor.d/tunables/alias || echo "alias /var/lib/mysql/ -> $MOUNT_POINT/mysql/," >> /etc/apparmor.d/tunables/alias

systemctl restart apparmor
/etc/init.d/apparmor reload
systemctl start mysql 