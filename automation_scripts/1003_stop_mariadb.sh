#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1003_stop_mariadb.sh
# Description   : Script to stop MariaDB service
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

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ $STATE == 'active' ]; then
   sudo $SYSCTL stop mariadb
   if [ $? -eq 0 ]; then
      STATUS="$HOSTNAME $(basename $0) - MariaDB Service is STOPPED successfully..."; echout "$STATUS"
   else
      STATUS="$HOSTNAME $(basename $0) - MariaDB Service FAILED to stop!!!"; echout "$STATUS"
      PrintExecStatus 1 "$STATUS"
      exit 1
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is ALREADY down..."; echout "$STATUS"
fi

PrintExecStatus 0 "$STATUS"
exit 0

