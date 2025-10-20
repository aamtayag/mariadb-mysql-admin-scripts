#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1011_full_mariadb_backup.sh
# Description   : Script to create full backup of MariaDB instance
#                 This script creates backup under /pmariabkup/fullbkup/ directory
#                 An optional DBdump (mysqldump) is created under /pmariabkup/fulldump/ folder
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-AUG-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 1 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>  \\033[0m" >&2
   echo  "For example :    $0   mariadb  "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ $STATE == 'active' ]; then

   #############################################################
   ### Backup using mariabackup
   #############################################################

   FULLDIR=$BKUPDIR/fullbkup/mariadb-fullbkup-$DATE
   if [ ! -d $FULLDIR ]; then
      $MKDIR -p $FULLDIR
      STATUS="BACKUP STARTED..."; echout "$STATUS"
      STATUS=$($MARIABKUP -u $USER -P $PORT -S $MYSOCK --backup --target-dir=$FULLDIR); echout "$STATUS"
      if [ $? -eq 0 ]; then
         STATUS="BACKUP COMPLETED SUCCESSFULLY..."; echout "$STATUS"   
      
         ###Prepare the backup###
         $MARIABKUP --prepare --target-dir=$FULLDIR
         STATUS="BACKUP HAS BEEN PREPARED..."; echout "$STATUS"

         ###Backup using mysqldump (not enabled by default). Set ENABLEDUMP=1 in setenv script to enable.
         if [ $ENABLEDUMP -eq 1 ]; then
            $MYSQLDUMP --single-transaction -u$USER -P$PORT -S $MYSOCK --all-databases | gzip > $BKUPDIR/fulldump/mariadb-fulldump-$DATE.dmp.gz
            STATUS="MYSQLDUMP COMPLETED SUCCESSFULLY..."; echout "$STATUS"
         fi

         ###Housekeep backups older than $BKUPRTN days
         BKUPRTNMIN=$[BKUPRTN*24*60]
         find $BKUPDIR/fullbkup/mariadb-full* -mmin +$BKUPRTNMIN -exec rm -rf {} \;
         find $BKUPDIR/fulldump/mariadb-full* -mmin +$BKUPRTNMIN -exec rm -rf {} \;
         STATUS="BACKUPS OLDER THAN $BKUPRTN days PURGED..."; echout "$STATUS"
      else
         STATUS="BACKUP FAILED!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"
         exit 1
     fi
   fi

else #service is down!!!
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't backup database..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

