#!/bin/bash
###micro/CentOS/Http&Https bc interacting with website
##########SETTING UP BACKEND DB FOR POSTGRES DJANGO SERVER##########
##########BASED ON##########
###Django is python
###https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-django-application-on-centos-7
###https://www.vultr.com/docs/install-phppgadmin-on-centos-7

##########DO NOT NEED FOR MANUAL BC ALREADY INSTALLED##########
##########ONLY FOR AUTOMATION########## 
sudo yum -y install epel-release
##########INSTALL PACKAGES GCC=GNU COMPILER##########
yum -y install python-pip python-devel gcc postgresql-server postgresql-devel postgresql-contrib
##########INITIALIZE POSTGRES##########
postgresql-setup initdb
##########START POSTGRES##########
systemctl start postgresql
##########EDIT CONFIG FILE AUTHENTICATION MODE TO MD5##########
###spaces important
#vim /var/lib/pgsql/data/pg_hba.conf
#sed -i 's,host    all             all             127.0.0.1/32            ident,host    all             all             127.0.0.1/32            md5,g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's,host    all             all             127.0.0.1/32            ident,host    all             all             0.0.0.0/0               md5,g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's,host    all             all             ::1/128                 ident,host    all             all             ::1/128                 md5,g' /var/lib/pgsql/data/pg_hba.conf
##########RESTART POSTGRES SERVICE##########
systemctl restart postgresql
##########ENABLE POSTGRES SERVICE##########
systemctl enable postgresql

echo "configuring PG admin"
##########CHANGE TO POSTGRES ADMIN USER THAT WAS CREATED DURING INSTALL TO RUN POSTGRES##########
####su - postgres "" won't run until something is in quotes
###shell login as postgres user to postgres database server
###psql
##########CREATE DATABASE FOR DJANGO PROJECT##########
###create a database user which we will use to connect to and interact with the database
###Set the password to something strong and secure
###Fine tuning for db
##########GIVE USER ALL PRIVILEGES##########
echo "CREATE DATABASE myproject;
CREATE USER myprojectuser WITH PASSWORD 'password';
ALTER ROLE myprojectuser SET client_encoding TO 'utf8';
ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE myprojectuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;" >> /tmp/tempfile

##########BECOME ADMIN AND RUN SCRIPT##########
###not working right now--issue with not jumping from server to database
###sudo -u postgres "psql -f /tmp/tempfile"
##########CURRENT SOLUTION##########
###changing into postgres user andrunning psql program to execute tempfile
sudo -u postgres /bin/psql -f /tmp/tempfile

echo "installing httpd"
##########Install Apache Web Server##########
yum install -y httpd
systemctl start httpd
systemctl enable httpd

##########configure SELinux##########
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_network_connect_db on

##########
yum install -y php php-pgsql

##########Install and configure PostgreSQL##########
##########Setup PostgreSQL listening addresses##########
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
###uncomment port
sed -i 's/#port = 5432/port = 5432/g' /var/lib/pgsql/data/postgresql.conf

###db user creds
echo "CREATE USER pgdbuser CREATEDB CREATEUSER ENCRYPTED PASSWORD 'pgdbpass';
CREATE DATABASE mypgdb OWNER pgdbuser;
GRANT ALL PRIVILEGES ON DATABASE mypgdb TO pgdbuser;" > /tmp/phpmyadmin

###changing in to postgres user and running psql program to execute phpmyadmin file
sudo -u postgres /bin/psql -f /tmp/phpmyadmin

##########Install and Use phpPgAdmin##########
yum install -y phpPgAdmin

##########configure phpPgAdmin as accessible from outside:##########
sed -i 's/Require local/Require all granted/g' /etc/httpd/conf.d/phpPgAdmin.conf
sed -i 's/Deny from all/Allow from all/g' /etc/httpd/conf.d/phpPgAdmin.conf
###need to escape brackets from search part of sed statement with \ before each bracket
sed -i "s/$conf\['servers'\]\[0\]\['host'\] = '';/$conf['servers'][0]['host'] = 'localhost';/g" /etc/phpPgAdmin/config.inc.php
sed -i "s/$conf\['owned_only'\] = false;/$conf\['owned_only'\] = true;/g" /etc/phpPgAdmin/config.inc.php
##########restarting postgres##########
systemctl restart httpd.service
systemctl restart postgresql

#setting up machine to run as client rsyslog to server rsyslog
#install this on a server
#rsyslog should be first server sun up
#client automation
sudo yum update -y && yum install -y rsyslog 	#CentOS 7
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
#on the client
#add to end of file
echo "*.* @@ldap-rsyslog-1:514" >> /etc/rsyslog.conf

##########Go to outside ip##########
#http://<ip>/phpPgAdmin/

########## ##########

##########BELOW ONLY NEEDED FOR MANUAL CONFIGURATION##########
###get out of database
#\q
###logout
#exit

##########POSSIBLE ISSUE WITH USER POSTGRES LOGIN AND PASSWORD##########
##Unable to log in as postgres user from reg user account requires passwd
##if i attempt to log into postgres from reg user, cannot access postgres OR root without password
