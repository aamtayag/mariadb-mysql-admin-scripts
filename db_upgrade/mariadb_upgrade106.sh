#!/bin/bash

##########################################################################
###
### MariaDB upgrade script from version 10.4 to 10.6
###
### Notes:
###    1. Need root privileges to execute
###
### Pre-requisite checks:
###    1. Make sure that option file has been migrated to latest version
###    2. Make sure to create a full backup before upgrading
###    3. Make sure that binary tar file has been copied to /root
###
##########################################################################

if [ $# -lt 2 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <OSVersion>   <BinaryTarFile> \\033[0m" >&2
   echo "For example :    $0     RHEL7      /root/mariadb-enterprise-10.6.7-3-rhel-7-x86_64-rpms.tar "
   exit 1
else
   OS=$1
   TAR=$2
fi

#OS='RHEL8'
#TAR='/root/mariadb-enterprise-10.6.7-3-rhel-7-x86_64-rpms.tar'
#TAR='/root/mariadb-enterprise-10.6.7-3-rhel-8-x86_64-rpms.tar'

export DATE=$(date '+%Y%m%d-%H%M%S')
export LOGDIR=/tmp

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE


#Create a backup before upgrading
STATE=$(systemctl status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')
if [ $STATE == 'active' ]; then
   #sudo -u mariadbp /home1/mariadbp/scripts/1011_full_mariadb_backup.sh mariadbp					##use this for UAT/PRD
   sudo -u mariadb /home1/mariadb/scripts/1011_full_mariadb_backup.sh mariadb						##use this for SIT
else
   echo "MariaDB Service is DOWN!!! Can't backup database..."
   exit 1
fi
echo



#Verify that binary tar file is copied to /root
ls -la $TAR																						##parameterized version
#ls -la /root/mariadb-enterprise-10.6.7-3-rhel-8-x86_64-rpms.tar
#ls -la /root/mariadb-enterprise-10.6.7-3-rhel-7-x86_64-rpms.tar
if [ $? -eq 0 ]; then
   tar -xvf $TAR -C /root/
   #tar -xvf /root/mariadb-enterprise-10.6.7-3-rhel-8-x86_64-rpms.tar -C /root/
   #tar -xvf /root/mariadb-enterprise-10.6.7-3-rhel-7-x86_64-rpms.tar -C /root/
else
   exit 1
fi
echo


#Stop MariaDB service
systemctl stop mariadb
STATE=$(systemctl status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')
if [ $STATE == 'active' ]; then
   echo "MariaDB still running, shut it down first!"
   exit 1
fi
echo


#Uninstall current MariaDB binaries
yum -y remove MariaDB-server
yum -y remove MariaDB-client
yum -y remove MariaDB-backup
yum -y remove MariaDB-compat
#Added for RHEL8
yum -y remove MariaDB-shared
echo


#Make sure all old MariaDB binaries are uninstalled before proceeding
rpm -qa | grep -i 'MariaDB*'
if [ $? -eq 0 ]; then
   echo "MariaDB rpm still exists!"
   exit 1
fi
echo


#Re-create soft link for server.cnf file under /etc/my.cnf.d
#ln -s /pmariadb/mariadb.6033/server.cnf /etc/my.cnf.d/server.cnf									##use this for UAT/PRD
ln -s /mariadb/mariadb.6033/server.cnf /etc/my.cnf.d/server.cnf										##use this for SIT


#Modify the repository configuration
cd /etc/yum.repos.d/
\cp -p mariadb.repo mariadb.repo.bak
echo "[local]
name=MariaDB ES 10.6
baseurl=file://${TAR::(-4)}
#baseurl=file:///root/mariadb-enterprise-10.6.7-3-rhel-8-x86_64-rpms
enabled=1
#gpgcheck=1
protect=1" > mariadb.repo


if [ $OS == 'RHEL7' ]; then
   \cp -p /etc/yum.repos.d/rhel-dvd.repo /etc/yum.repos.d/rhel-dvd.repo.bak
   sed 's/\gpgcheck/#gpgcheck/g' /etc/yum.repos.d/rhel-dvd.repo.bak > /etc/yum.repos.d/rhel-dvd.repo
elif [ $OS == 'RHEL8' ]; then
   \cp -p /etc/yum.repos.d/media.repo /etc/yum.repos.d/media.repo.bak
   sed 's/\gpgcheck/#gpgcheck/g' /etc/yum.repos.d/media.repo.bak > /etc/yum.repos.d/media.repo
   \cp -p /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/redhat.repo.bak
   sed 's/\gpgcheck/#gpgcheck/g' /etc/yum.repos.d/redhat.repo.bak > /etc/yum.repos.d/redhat.repo
fi

\cp -p /etc/yum.conf /etc/yum.conf.bak
sed 's/\gpgcheck/#gpgcheck/g' /etc/yum.conf.bak > /etc/yum.conf


#For RHEL8, need to perform extra steps
if [ $OS == 'RHEL8' ]; then
   yum -y config-manager --disable LocalRepo_AppStream
   cd /root/Packages/AppStream/Packages
   #get the biggest perl package and install it
   #PERL=$(ls -rS *perl-DBI* | tail -1)
   #rpm -ivh $PERL
   #if [ $? -ne 0 ]; then
      #failed so try again!!! get the latest perl package and install it
      #PERL=$(ls -rt *perl-DBI* | tail -1)
      #rpm -ivh $PERL
      #if [ $? -ne 0 ]; then
         #echo "Perl package installation has failed! PLs check this!!!"
         #exit 1
      #fi
   #fi
   find . -name "perl-DBI*" | while read -r file; do
      temp=`echo "$file" | cut -c 3-`
      echo "Installing package \"$temp\""
      rpm -ivh $temp
      if [ $? -eq 0 ]; then
         echo "Successfully installed package \"$temp\""
         break
      fi
   done
fi
echo


#Install MariaDB 10.6 binaries
yum -y install MariaDB-server
yum -y install MariaDB-backup
yum -y install MariaDB-cracklib-password-check


##Modify mariadb.service file
systemctl disable mariadb

cd /usr/lib/systemd/system
\cp -p mariadb.service mariadb.service.bak
sed 's/\User=mysql/User=mariadb/g' mariadb.service.bak > mariadb.service1
sed 's/\Group=mysql/Group=gmariadb/g' mariadb.service1 > mariadb.service
chown root:root mariadb.service

systemctl enable mariadb


#Remove all other files in /etc/my.cnf.d folder except server.cnf
cd /etc/my.cnf.d
ls | grep -v server.cnf | xargs rm
ls server.cnf.* | xargs rm


#Change permission of MariaDB data directory
#chown -R mariadbp:gmariadb /pmariadata																##use this for UAT/PRD
chown -R mariadb:gmariadb /mariadata																##use this for SIT



#Remove mysql user & group
userdel mysql


#Start the MariaDB service and run the upgrade
systemctl start mariadb
#sudo -u mariadbp mariadb-upgrade -u mariadbp -P6033 -S /pmariatmp/mariadb.6033.sock				##use this for UAT/PRD
sudo -u mariadb mariadb-upgrade -u mariadb -P6033 -S /mariatmp/mariadb.6033.sock					##use this for SIT
if [ $? -eq 0 ]; then
   echo "MariaDB upgrade is successful!"
else
   echo "MariaDB upgrade is NOT successful!"
   exit 1
fi


#Perform cleanup & revert repository to original configuration
rm -f /usr/lib/systemd/system/mariadb.service1
\cp -p /etc/yum.conf.bak /etc/yum.conf

if [ $OS == 'RHEL7' ]; then
   \cp -p /etc/yum.repos.d/rhel-dvd.repo.bak /etc/yum.repos.d/rhel-dvd.repo
elif [ $OS == 'RHEL8' ]; then
   \cp -p /etc/yum.repos.d/media.repo.bak /etc/yum.repos.d/media.repo
   \cp -p /etc/yum.repos.d/redhat.repo.bak /etc/yum.repos.d/redhat.repo
fi

echo "[local]
name=MariaDB ES 10.6
baseurl=file://${TAR::(-4)}
#baseurl=file:///root/mariadb-enterprise-10.6.7-3-rhel-7-x86_64-rpms
enabled=1
gpgcheck=1
protect=1" > /etc/yum.repos.d/mariadb.repo


#Enable again LocalRepo_AppStream (RHEL8 only)
if [ $OS == 'RHEL8' ]; then
   yum -y config-manager --enable LocalRepo_AppStream
fi
echo


exit 0
