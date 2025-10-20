#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1000_setenv_mariadb.sh
# Description   : Script to set environment variables for MariaDB
# Created By    : Arnold Aristotle Tayag
# Created On    : 18-MAY-2021
#---------------------------------------------------------------------------------------#


################################################
### Static variable definitions
################################################

export MYSQL=$(which mysql)
export MAIL=$(which mail)
export MKDIR=$(which mkdir)
export MARIABKUP=$(which mariabackup)
export MYSQLDUMP=$(which mysqldump)
export SYSCTL=$(which systemctl)
#export SUDOSTAT=$(sudo systemctl status mariadb)
#export SUDOSTOP=$(sudo systemctl stop mariadb)
#export SUDOSTART=$(sudo systemctl start mariadb)
#export SUDORESTART=$(sudo systemctl restart mariadb)
export MYADMIN=$(which mysqladmin)
export PORT=6033
export BKUPRTN=2
export ENABLEDUMP=0
export HOSTNAME=$(hostname | awk '{print toupper($0)}')
export DATE=$(date '+%Y%m%d-%H%M%S')
export EMAILID=sgmonitoringmariadb@uobgroup.com

### Static variables for MariaDB version 10.4 and up
export MYMARIA=$(which mariadb)


################################################
### Common function definitions
################################################

echout() {
   echo -e "\\033[32m $1 \\033[0m" | tee -a $LOG
}


PrintExecStatus() {
   echo
   if [ $1 -eq 0 ]; then
      echout "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      echout "+++ $HOSTNAME $(basename $0) execution is OK..."
   else
      echout "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      echout "+++ $HOSTNAME $(basename $0) execution is KO..."
   fi
   echout "+++ Logfile: $LOG"
   echout "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   
   ###Check if need to enable email sending!!!
   #$MAIL -s "$2" "$EMAILID" < $LOG
}


################################################
### Non-Static variable definitions
################################################

if [ -d /pmariadata ]; then
   ### Set environment variables for UAT/PRD environment ###
   export HOMEDIR=/home1/mariadbp
   export DATADIR=/pmariadata
   export BKUPDIR=/pmariabkup
   export LOGDIR=/home1/mariadbp/scripts/temp
   export ERRDIR=/pmarialogs/mysql
   export AUDDIR=/pmariaaudlogs
   export BINDIR=/pmariabinlogs
   export CONFDIR=/pmariadb/mariadb.6033
   export MYSOCK=/pmariatmp/mariadb.6033.sock
elif [ -d /mariadata ]; then
   ### Set environment variables for SIT/DEV environment ###
   export HOMEDIR=/home1/mariadb
   export DATADIR=/mariadata
   export BKUPDIR=/mariabkup
   export LOGDIR=/home1/mariadb/scripts/temp
   export ERRDIR=/marialogs/mysql
   export AUDDIR=/mariaaudlogs
   export BINDIR=/mariabinlogs
   export CONFDIR=/mariadb/mariadb.6033
   export MYSOCK=/mariatmp/mariadb.6033.sock
else
   echo -e "\\033[32m Error in locating MariaDB file systems. PLEASE check!!! \\033[0m"
   exit 1
fi

