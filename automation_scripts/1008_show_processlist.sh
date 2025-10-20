#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1008_show_processlist.sh
# Description   : Script to show process list for running MariaDB service
# Created By    : Arnold Aristotle Tayag
# Created On    : 12-AUG-2021
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
   STATUS=$($MYADMIN -u $USER -S $MYSOCK --verbose processlist); echout "$STATUS"
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't query process information..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

