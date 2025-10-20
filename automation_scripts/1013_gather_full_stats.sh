#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1013_gather_full_stats.sh
# Description   : Script to gather/update statistics for all tables
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-SEP-2021
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
   MYCONN="$MYSQL -u $USER -P $PORT -S $MYSOCK"
   DBLIST=$($MYCONN -r -B -N -e "show databases;")
   DBNAMES=`echo $DBLIST | tr ' ' '\n' | grep -viP "(information_schema|mysql|performance_schema|sys)" | tr '\n' ' '`
   for DB in $DBNAMES; do
      TBLIST=$($MYCONN -r -B -N -e "show tables from $DB;")
      if [ -z "$TBLIST" ]; then
         STATUS="Table/s not found in database \"$DB\""; echout "$STATUS"
      else
         for TBLNAME in $TBLIST; do
            STATUS="Analyzing table \"$DB:$TBLNAME\"..."; echout "$STATUS"
            $MYCONN -D $DB -e "analyze table $TBLNAME persistent for all;"            
            if [ $? -eq 0 ]; then
               echo " "
            else
               STATUS="Failed to analyze table $DB:$TBLNAME!!!" echout "$STATUS"
            fi
         done
      fi
      STATUS="Gather full table stats job is DONE..."; echout "$STATUS"
   done
else #service is down!!!
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Not able to gather table stats..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

