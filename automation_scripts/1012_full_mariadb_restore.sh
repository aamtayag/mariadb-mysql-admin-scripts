#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1012_full_mariadb_restore.sh
# Description   : Script to restore instance from full DB backup
#                 Backups for restoration are taken from /pmariabkup/fullbkup/
#                 Specify ONLY the directory of backup to be used for restore, not the full path
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-AUG-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 2 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>         <BKUPDirectory> \\033[0m" >&2
   echo  "For example :    $0    mariadb   mariadb-full-backup-2019-03-28 "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
   FULLDIR=$BKUPDIR/fullbkup/$2
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

RestoreDB() {
   rm -rf $DATADIR/*
   $MARIABKUP --copy-back --datadir=$DATADIR --target-dir=$FULLDIR
   if [ $? -eq 0 ]; then
      STATUS="DATABASE RESTORATION COMPLETED SUCCESSFULLY..."; echout "$STATUS"
      chown -R $USER:gmariadb $DATADIR
      find $DATADIR/* -type f -exec chmod 660 {} \;
      sudo $SYSCTL restart mariadb
      if [ $? -eq 0 ]; then
         STATUS="MariaDB Service is started SUCCESSFULLY..."; echout "$STATUS"         
      else
         STATUS="MariaDB Service FAILED to start after restore!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"         
         exit 1
      fi
   else
      STATUS="DATABASE RESTORATION FAILED!!!"; echout "$STATUS"
      PrintExecStatus 1 "$STATUS"
      exit 1
   fi
}

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ $STATE == 'active' ]; then
   sudo $SYSCTL stop mariadb
   if [ $? -eq 0 ]; then
      STATUS="MariaDB Service has been STOPPED..."; echout "$STATUS"
      STATUS="Now performing database restoration..."; echout "$STATUS"
      RestoreDB
   else
      STATUS="MariaDB Service FAILED to stop!!!"; echout "$STATUS"
      PrintExecStatus 1 "$STATUS"  
      exit 1
   fi
elif [ $STATE == 'inactive' ] || [ $STATE == 'failed' ]; then
   STATUS="MariaDB Service is INACTIVE..."; echout "$STATUS"
   STATUS="Now performing restoration..."; echout "$STATUS"   
   RestoreDB
fi

PrintExecStatus 0 "$STATUS"
exit 0

