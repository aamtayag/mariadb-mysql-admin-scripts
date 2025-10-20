#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1010_drop_dbuser.sh
# Description   : Script to drop a database user
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-AUG-2021
# Modified On   : 01-MAR-2022
#                 1. Added extra logic to prevent dropping of non-application users
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 3 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>  <DBUserName>  <Host> \\033[0m" >&2
   echo  "For example :    $0    mariadb     mrsgpadm      %  "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
   DBUSER=$2
   HOST=$3
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ "$DBUSER" == 'root' -o "$DBUSER" == 'mariadbp' -o "$DBUSER" == 'dbadmin' -o "$DBUSER" == 'repadmin' -o "$DBUSER" == 'maxadmin' -o "$DBUSER" == 'maxuser' ]; then
   STATUS="$HOSTNAME $(basename $0) - Only application users can be dropped!!!"; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

if [ $STATE == 'active' ]; then
   USEREXIST=$($MYSQL -u $USER -S $MYSOCK -s -e "select user from mysql.user where user='$DBUSER' and host='$HOST';")
   if [ "$USEREXIST" == "$DBUSER" ]; then
      STATUS="Dropping user \"$DBUSER@'$HOST'\"..."; echout "$STATUS"
      $MYSQL -u $USER -S $MYSOCK -e "drop user $DBUSER@'$HOST';"
      if [ $? -eq 0 ]; then
         STATUS="User \"$DBUSER@'$HOST'\" has been dropped..."; echout "$STATUS"
      else
         STATUS="Error in dropping user!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"
         exit 1
      fi
   else
      STATUS="User \"$DBUSER@'$HOST'\" does not exist..."; echout "$STATUS"
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't drop user..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

