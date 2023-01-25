#!/bin/bash
#
#centos7.4编译安装mysql
sourceinstall=/usr/local/src/mysql5.7
chmod 777 -R $sourceinstall
cd $sourceinstall
#rpm -ivh $sourceinstall/rpm/*.rpm --force --nodeps

sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 
setenforce 0 && systemctl stop iptables && systemctl disable iptables


rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
yum -y install epel-release
yum install -y apr* autoconf automake bison bzip2 bzip2* compat* cpp curl curl-devel fontconfig fontconfig-devel freetype freetype* freetype-devel gcc gcc-c++ gd gettext gettext-devel glibc kernel kernel-headers keyutils keyutils-libs-devel krb5-devel libcom_err-devel libpng libpng-devel libjpeg* libsepol-devel libselinux-devel libstdc++-devel libtool* libgomp libxml2 libxml2-devel libXpm* libtiff libtiff* make mpfr ncurses* ntp openssl openssl-devel patch pcre-devel perl php-common php-gd policycoreutils telnet t1lib t1lib* nasm nasm* wget zlib-devel texlive-latex texlive-metapost texlive-collection-fontsrecommended --skip-broken
yum install -y apr* autoconf automake bison bzip2 bzip2* compat* cpp curl curl-devel fontconfig fontconfig-devel freetype freetype* freetype-devel gcc gcc-c++ gd gettext gettext-devel glibc kernel kernel-headers keyutils keyutils-libs-devel krb5-devel libcom_err-devel libpng libpng-devel libjpeg* libsepol-devel libselinux-devel libstdc++-devel libtool* libgomp libxml2 libxml2-devel libXpm* libtiff libtiff* make mpfr ncurses* ntp openssl openssl-devel patch pcre-devel perl php-common php-gd policycoreutils telnet t1lib t1lib* nasm nasm* wget zlib-devel texlive-latex texlive-metapost texlive-collection-fontsrecommended --skip-broken

cd $sourceinstall
mkdir -pv /usr/local/cmake
tar -xzvf cmake-3.9.3.tar.gz -C /usr/local/cmake
cd /usr/local/cmake/cmake-3.9.3/
./configure
make && make install

#1、卸载mysql和marriadb
yum -y remove mysql*
yum -y remove mariadb*
yum -y remove boost*
rpm -e --nodeps `rpm -qa | grep mariadb`
rpm -e --nodeps `rpm -qa | grep mysql`
rpm -e --nodeps `rpm -qa | grep boost`
#2、配置Mysql服务
cd $sourceinstall
groupadd mysql
useradd -g mysql -s /sbin/nologin mysql
mkdir -pv /usr/local/mysql/boost
mv boost_1_59_0.tar.gz /usr/local/mysql/boost
mkdir -pv /usr/local/mysql/{data,conf,logs}
tar -zxvf mysql-5.7.24.tar.gz -C /usr/local/mysql
cd /usr/local/mysql/mysql-5.7.24/
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/usr/local/mysql/data -DSYSCONFDIR=/usr/local/mysql/conf -DMYSQL_USER=mysql -DMYSQL_UNIX_ADDR=/usr/local/mysql/logs/mysql.sock -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci -DMYSQL_TCP_PORT=3306 -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DWITH_SSL:STRING=bundled -DWITH_ZLIB:STRING=bundled -DENABLE_DOWNLOADS=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/usr/local/mysql/boost -DENABLE_DTRACE=0
make -j `grep processor /proc/cpuinfo | wc -l`
make install
make clean
rm CMakeCache.txt
chown -Rf mysql:mysql /usr/local/mysql

cat > /usr/local/mysql/conf/my.cnf <<EOF
[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4

[mysqld]
port = 3306
socket = /usr/local/mysql/logs/mysql.sock
pid-file = /usr/local/mysql/mysql.pid
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
tmpdir = /tmp
user = mysql
log-error = /usr/local/mysql/logs/mysql.log
slow_query_log = ON
long_query_time = 1
server-id = 1 
log-bin = mysql-bin
binlog-format=ROW
#max_allowed_packet = 64M
max_connections=1000
log_bin_trust_function_creators=1
character-set-client-handshake = FALSE
character-set-server = utf8mb4 
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'
lower_case_table_names = 0
sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'

bulk_insert_buffer_size = 100M

# -------------- #
# InnoDB Options #
# -------------- #
innodb_buffer_pool_size = 4G
innodb_log_buffer_size = 16M
innodb_log_file_size = 256M
max_binlog_cache_size = 2G
max_binlog_size = 1G
expire_logs_days = 7
EOF
chown -Rf mysql:mysql /usr/local/mysql
#二进制程序：
echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh 
source /etc/profile.d/mysql.sh
#头文件输出给系统：
ln -sv /usr/local/mysql/include /usr/include/mysql
#库文件输出：MySQL数据库的动态链接库共享至系统链接库,一般MySQL数据库会被PHP等服务调用
echo '/usr/local/mysql/lib' > /etc/ld.so.conf.d/mysql.conf
ln -s /usr/local/mysql/lib/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.20
#让系统重新生成库文件路径缓存
ldconfig
#导出man文件：
echo 'MANDATORY_MANPATH                       /usr/local/mysql/man' >> /etc/man_db.conf

cat > /usr/lib/systemd/system/mysqld.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/usr/local/mysql/conf/my.cnf
LimitNOFILE = 5000
Restart=on-failure
RestartPreventExitStatus=1
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

/usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data/
systemctl daemon-reload
systemctl enable mysqld.service
systemctl restart mysqld.service
chown -Rf mysql:mysql /usr/local/mysql


#查看默认root本地登录密码如果不是用空密码初始化的数据库则：
grep 'temporary password' /usr/local/mysql/logs/mysql.log | awk -F: '{print $NF}'
systemctl stop mysqld.service
echo 'skip-grant-tables' >> /usr/local/mysql/conf/my.cnf
systemctl restart mysqld.service 
sleep 5
mysql -uroot -e "update mysql.user set authentication_string=PASSWORD('Root_123456*0987') where User='root';";
sed -i 's|skip-grant-tables|#skip-grant-tables|' /usr/local/mysql/conf/my.cnf;
systemctl restart mysqld.service;
sleep 5
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root_123456*0987';";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root_123456*0987' WITH GRANT OPTION;";
mysql -uroot -pRoot_123456*0987 --connect-expired-password -e "flush privileges;";

firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent
firewall-cmd --permanent --query-port=3306/tcp
firewall-cmd --reload


#systemctl stop mysqld.service
#echo 'skip-grant-tables' >> /usr/local/mysql/conf/my.cnf
#systemctl restart mysqld.service 
#sleep 5
#mysql -uroot < $sourceinstall/mydbpassword.sql
#systemctl stop mysqld.service

#cat >> /usr/local/mysql/conf/my.cnf <<EOF
#[client]
#host=localhost
#user=root
#password='Root_123456*0987'
#EOF
#sed -i 's|skip-grant-tables|#skip-grant-tables|' /usr/local/mysql/conf/my.cnf
#systemctl restart mysqld.service 
#sleep 5

#sed -i '8,12d' /usr/local/mysql/conf/my.cnf
#chown -Rf mysql:mysql /usr/local/mysql
rm -rf $sourceinstall
#修改root本地登录密码
#mysql_secure_installation
#Change the password for root ? y
#New password:Xsssx1231231
#Remove anonymous users?  y
#Disallow root login remotely? y
#Remove test database and access to it?  y
#Reload privilege tables now?  y
#All done! 

#root用户登录测试
#mysql -uroot -pRoot_123456*0987

#更改用户密码命令
#ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root_123456*0987';

#防火墙开放mysql端口
#firewall-cmd --permanent --zone=public --add-port=3306/tcp --permanent;
#firewall-cmd --permanent --query-port=3306/tcp;
#firewall-cmd --reload;
#lsof -i:3306

#开放 Root 远程连接权限
#GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Root_123456*0987' WITH GRANT OPTION; 

#创建用户：CREATE USER 'springdev'@'host' IDENTIFIED BY 'springdev_mysql';
#授权：GRANT ALL PRIVILEGES ON *.* TO 'springdev'@'%' IDENTIFIED BY 'springdev_mysql' WITH GRANT OPTION;
#刷新：flush privileges;
#创库：CREATE DATABASE springdev default charset 'utf8mb4';

#RHEL7使用xtrbackup还原增量备份:https://www.percona.com/downloads/
#chmod -R 777  $sourceinstall/percona-xtrabackup-24-2.4.7-2.el7.x86_64.rpm
#yum -y install percona-xtrabackup-24-2.4.7-2.el7.x86_64.rpm 
#做一次完整备份
#innobackupex --password=Root_123456*0987 /data/db_backup/
#ls -ld /data/db_backup/2017-08-02_13-43-38/
#mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'
#mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values(1000);'
#第一次增量备份：第一次备份的–incremental-basedir参数应指向完整备份的时间戳目录
#innobackupex --password=Root_123456*0987 --incremental /data/db_backup/ --incremental-basedir=/data/db_backup/2017-08-02_13-43-38/
#ls -ld /data/db_backup/2017-08-02_13-49-29/
#mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values(2000);'
#第二次增量备份：第二次备份的–incremental-basedir参数应指向第一次增量备份的时间戳目录
#innobackupex --password=Root_123456*0987 --incremental /data/db_backup/ --incremental-basedir=/data/db_backup/2017-08-02_13-49-29/
#还原数据
#systemctl daemon-reload && systemctl stop mysqld && netstat -lanput |grep 3306
#rm -rf /var/lib/mysql/*
#整合完整备份和增量备份：注意：一定要按照完整备份、第一次增量备份、第二次增量备份的顺序进行整合，在整合最后一次增量备份时不要使用–redo-only参数
#innobackupex --apply-log --redo-only /data/db_backup/2017-08-02_13-43-38/
#innobackupex --apply-log --redo-only /data/db_backup/2017-08-02_13-43-38/ --incremental-dir=/data/db_backup/2017-08-02_13-49-29/
#innobackupex --apply-log /data/db_backup/2017-08-02_13-43-38/ --incremental-dir=/data/db_backup/2017-08-02_13-52-59/ 
#innobackupex --apply-log /data/db_backup/2017-08-02_13-43-38/
#开始还原
#innobackupex --copy-back /data/db_backup/2017-08-02_13-43-38/
#chown -R mysql.mysql /var/lib/mysql 
#systemctl daemon-reload && systemctl restart mysqld && netstat -lanput |grep 3306
#mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'


############################################（一）RHEL7上面搭建主从#########################################
###IP地址：192.168.8.20 Master   IP地址：192.168.8.21 Slave
###########------------------------------------主服务器（master）------------------------------#############
# mysql -uroot -pRoot_123456*0987 -e 'create database Yang default charset "utf8mb4";'
# mysql -uroot -pRoot_123456*0987 -e 'use Yang;create table T1(ID int);'
# mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values (100);'
# mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'
# mysqldump -uroot -pRoot_123456*0987 -B Yang > Yang.sql
# scp Yang.sql 192.168.8.21:/root/
#systemctl daemon-reload && systemctl stop mysqld.service && netstat -lanput |grep 3306
#cat >> /usr/local/mysql/conf/my.cnf <<EOF 
#log-bin = mysql-bin
#server-id = 1 
#EOF
# systemctl daemon-reload && systemctl restart mysqld && netstat -lanput |grep 3306
# mysql -uroot -pRoot_123456*0987 -e 'grant replication slave on *.* to slave@192.168.8.21 identified by "qwerASDF@123456";'
# mysql -uroot -pRoot_123456*0987 -e 'show master status;'

###########------------------------------------从服务器（slave）------------------------------#############
# mysql -uslave -pqwerASDF@Root_123456*0987 -h 192.168.8.20
# cd && mysql -uroot -pRoot_123456*0987 < Yang.sql
# cat >> /usr/local/mysql/conf/my.cnf <<EOF
# server-id = 2
# replicate_do_db=Yang
# relay-log= relay-mysql
# read-only=ON
# EOF
# systemctl daemon-reload && systemctl restart mysqld && netstat -lanput |grep 3306
# mysql -uroot -pRoot_123456*0987 -e 'change master to master_host="192.168.8.20",master_user="slave",master_password="qwerASDF@123456"'
# mysql -uroot -pRoot_123456*0987 -e 'start slave;'
# mysql -uroot -pRoot_123456*0987 -e 'show slave status\G' |egrep "Slave_IO_Running|Slave_SQL_Running"

#连接测试：
#在主服务器上插入数据 mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values(6666);'
#在主服务器上查看数据 mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'
#在从服务器上查看数据 mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'



############################################（二）RHEL7上面搭建主主#########################################
###IP地址：192.168.8.20 Master   IP地址：192.168.8.21 Master 
###########------------------------------------主服务器A（master）------------------------------#############
#systemctl daemon-reload && systemctl stop mysqld.service && netstat -lanput |grep 3306
#cat >> /usr/local/mysql/conf/my.cnf <<EOF 
#server-id = 1  
#log-bin = mysql-bin
#relay-log = relay-mysql
#auto-increment-offset = 1
#auto-increment-increment = 2
#EOF
# systemctl daemon-reload && systemctl restart mysqld && netstat -lanput |grep 3306
# mysql -uroot -pRoot_123456*0987 -e 'grant replication slave on *.* to slave@192.168.8.21 identified by "qwerASDF@123456";'
# mysql -uroot -pRoot_123456*0987 -e 'change master to master_host="192.168.8.21",master_user="slave",master_password="qwerASDF@123456"'
# mysql -uroot -pRoot_123456*0987 -e 'start slave;'
# mysql -uroot -pRoot_123456*0987 -e 'show master status;'

###########------------------------------------主服务器B（master）------------------------------#############
# mysql -uslave -pqwerASDF@Root_123456*0987 -h 192.168.8.20
# systemctl daemon-reload && systemctl stop mysqld.service && netstat -lanput |grep 3306
#cat >> /usr/local/mysql/conf/my.cnf <<EOF 
#server-id = 2  
#log-bin = mysql-bin
#relay-log = relay-mysql
#auto-increment-offset = 2 
#auto-increment-increment = 2
#EOF
# systemctl daemon-reload && systemctl restart mysqld && netstat -lanput |grep 3306
# mysql -uroot -pRoot_123456*0987 -e 'grant replication slave on *.* to slave@192.168.8.20 identified by "qwerASDF@123456";'
# mysql -uroot -pRoot_123456*0987 -e 'change master to master_host="192.168.8.20",master_user="slave",master_password="qwerASDF@123456"'
# mysql -uroot -pRoot_123456*0987 -e 'start slave;'
# mysql -uroot -pRoot_123456*0987 -e 'show slave status\G' |egrep "Slave_IO_Running|Slave_SQL_Running"

#连接测试：
# mysql -uroot -pRoot_123456*0987 -e 'create database Yang default charset "utf8mb4";'
# mysql -uroot -pRoot_123456*0987 -e 'use Yang;create table T1(ID int);'
# mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values (1000);'
# mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'
#在主服务器上插入数据 mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values(6666);'
#在从服务器上插入数据 mysql -uroot -pRoot_123456*0987 -e 'insert into Yang.T1 values(7777);'
#在主服务器上查看数据 mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'
#在从服务器上查看数据 mysql -uroot -pRoot_123456*0987 -e 'select * from Yang.T1;'


#为了复制的安全性：
#			sync_master_info = 1    
#			sync_relay_log = 1   
#			sync_relay_log_info = 1
#从服务器意外崩溃时，建议使用pt-slave-start命令来启动slave; 
#评估主从服务表中的数据是否一致：pt-table-checksum

#如果数据不一致办法1、重新备份并在从服务器导入数据；2、pt-table-sync 


#为了提高复制时的数据安全性，在主服务器上的设定：
#	sync_binlog = 1
#	innodb_flush_log_at_trx_commit = 1
#此参数设定为1，性能下降严重；一般设为2等，此时主服务器崩溃依然有可能导致从服务器无法获取到全部的二进制日志事件；
#
#master崩溃导致二进制日志损坏，在从服务器使用参数忽略：sql_slave_skip_counter = 0

#在线安全的清空慢查询日志
#set global slow_query_log=0;
#show variables like '%slow%';
#set global slow_query_log_file='/usr/local/mysql/data/zabbixserver-slow.log';
#set global slow_query_log=1;
