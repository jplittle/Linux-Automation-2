#!/bin/bash
############AUTOMATE NFS SERVER INSTALL############
###https://www.howtoforge.com/nfs-server-and-client-on-centos-7
yum install -y nfs-utils

############CREATE PLACE TO HOUSE STUFF############
mkdir /var/nfsshare /var/nfsshare/devstuff /var/nfsshare/testing /var/nfsshare/home_dirs
############OPEN TO ALL FOR PROBLEM SOLVING: READING, WRITING, EXECUTING############
###enables root to read through newly
chmod -R 777 /var/nfsshare/
############ENABLE AND STARTING SERVICES TO RUN AT BOOT############
for service in rpcbind nfs-server nfs-lock nfs-idmap; do echo "systemctl enable $service"; done
for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl start $service; done
for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl enable $service; done
for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl start $service; done
############SHARE NFS DIRECTORY WITH NETWORK############
cd /var/nfsshare/
echo "/var/nfsshare/home_dirs *(rw,sync,no_all_squash)
/var/nfsshare/devstuff *(rw,sync,no_all_squash)
/var/nfsshare/testing *(rw,sync,no_all_squash)" >> /etc/exports
systemctl restart nfs-server
yum -y install net-tools
showmount -e $ipaddress
mkdir /mnt/test
ifconfig
echo "10.142.0.11:/var/nfsshare/testing     /mnt/test     nfs     defaults 0 0" >> /etc/fstab
mount -a
showmount -e $ipaddress
showmount -e 10.142.0.11

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
