#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1004_restart_mariadb.sh
# Description   : Script to restart MariaDB service
# Created By    : Arnold Aristotle Tayag
# Created On    : 18-MAY-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

sudo $SYSCTL restart mariadb
if [ $? -eq 0 ]; then
   STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')
   if [ $STATE == 'active' ]; then
      STATUS="$HOSTNAME $(basename $0) - MariaDB Service is RESTARTED successfully..."; echout "$STATUS"
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service FAILED to restart!!!"; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

