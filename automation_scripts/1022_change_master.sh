#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1014_change_master.sh
# Description   : Script to configure slave/replica in a replication environment
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-SEP-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 5 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUser>  <MasterHost>  <RepUser>  <RepUserPwd>  <GTIDPos> \\033[0m" >&2
   echo  "For example :    $0   mariadb   172.28.19.160  repAdmin   repAdminPwd     7002 "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
   MHOST=$2
   REPUSER=$3
   REPUSERPWD=$4
   GTIDPOS=$5
fi

#LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1

$MYSQL -u $USER -S $MYSOCK -e "stop slave;"


$MYSQL -u $USER -S $MYSOCK -e "change master to \
                               master_host=$MHOST, \
                               master_user=$REPUSER, \
                               master_password=$REPUSERPWD, \
                               master_use_gtid=$GTIDPOS;"

$MYSQL -u $USER -S $MYSOCK -e "start slave;"

$MYSQL -u $USER -S $MYSOCK -e "show slave status\G"

echo
echo "########################################################"
echo -e "\\033[32m $HOSTNAME $(basename $0) execution is OK... \\033[0m"
echo "########################################################"
exit 0

