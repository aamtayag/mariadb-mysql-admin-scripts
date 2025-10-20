#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1001_status_mariadb.sh
# Description   : Script to verify status of MariaDB service
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
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is RUNNING..."; echout "$STATUS"
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN..."; echout "$STATUS"
fi

PrintExecStatus 0 "$STATUS"
exit 0

