#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1006_drop_database.sh
# Description   : Script to drop a database/schema
# Created By    : Arnold Aristotle Tayag
# Created On    : 18-MAY-2021
# Modified On   : 24-FEB-2022
# Modified On   : 01-MAR-2022
#                 1. Added extra logic to prevent dropping system databases,
#                    i.e. information_schema, performance_schema, mysql, sys
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 2 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>   <DBName> \\033[0m" >&2
   echo  "For example :    $0    mariadb   myDatabase "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
   DATABASE=$2
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ "$DATABASE" == 'information_schema' -o "$DATABASE" == 'performance_schema' -o "$DATABASE" == 'mysql' -o "$DATABASE" == 'sys' ]; then
   STATUS="$HOSTNAME $(basename $0) - System databases CANNOT be dropped!!!"; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

if [ $STATE == 'active' ]; then
   MYCONN="$MYSQL -u $USER -P $PORT -S $MYSOCK"
   DBNAME=$($MYCONN -r -B -N -e "SHOW DATABASES LIKE '$DATABASE';")
   if [ "$DBNAME" == "$DATABASE" ]; then
      STATUS="Dropping database \"$DATABASE\"..."; echout "$STATUS"
      $MYCONN -e  "DROP DATABASE $DATABASE;"
      if [ $? -eq 0 ]; then
         STATUS="Database \"$DATABASE\" dropped SUCCESSFULLY..."; echout "$STATUS"
      else
         STATUS="ERROR in dropping database!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"
         exit 1
      fi
   else
      STATUS="Database \"$DATABASE\" DOES NOT exist!!!"; echout "$STATUS"
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't drop database..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

