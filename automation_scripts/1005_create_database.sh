#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1005_create_database.sh
# Description   : Script to create a new database/schema
# Created By    : Arnold Aristotle Tayag
# Created On    : 18-MAY-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 2 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>   <DBName> \\033[0m" >&2
   echo  "For example :    $0    mariadb    myNewDB "
   exit $E_NOARGS	#Return 85 as exit status of script (error code)
else
   USER=$1
   DATABASE=$2
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ $STATE == 'active' ]; then
   MYCONN="$MYSQL -u $USER -P $PORT -S $MYSOCK"
   DBNAME=$($MYCONN -r -B -N -e "SHOW DATABASES LIKE '$DATABASE';")
   if [ "$DBNAME" == "$DATABASE" ]; then
      STATUS="Database \"$DATABASE\" ALREADY exist!!!"; echout "$STATUS"
   else
      STATUS="Creating database \"$DATABASE\"..."; echout "$STATUS"
      $MYCONN -e  "CREATE SCHEMA IF NOT EXISTS $DATABASE;"
      if [ $? -eq 0 ]; then
         STATUS="Database \"$DATABASE\" created SUCCESSFULLY..."; echout "$STATUS"
      else
         STATUS="ERROR in database creation!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"
         exit 1
      fi
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't create database..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

