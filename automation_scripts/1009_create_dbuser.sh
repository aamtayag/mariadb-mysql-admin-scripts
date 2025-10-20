#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : 1009_create_dbuser.sh
# Description   : Script to create a new DB user
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-AUG-2021
#---------------------------------------------------------------------------------------#

if [ -d /pmariadata ]; then
   . /home1/mariadbp/scripts/1000_setenv_mariadb.sh
else
   . /home1/mariadb/scripts/1000_setenv_mariadb.sh
fi

if [ $# -lt 4 ]; then
   echo "To execute this script, the following parameters are required:"
   echo -e "\\033[32m \t\t $0  <AuthUSER>  <DBUserName>  <Host>  <Password> \\033[0m" >&2
   echo  "For example :    $0    mariadb     mrsgpadm      %       myPass "
   exit $E_NOARGS       #Return 85 as exit status of script (error code)
else
   USER=$1
   DBUSER=$2
   HOST=$3
   PWD=$4
fi

LOGFILE=$(basename $0 | cut -d '.' -f 1)_${DATE}.log
#exec > $LOGDIR/$LOGFILE 2>&1
LOG=$LOGDIR/$LOGFILE

STATE=$(sudo $SYSCTL status mariadb | grep "Active:" | cut -d ":" -f 2 | awk '{print $1}')

if [ $STATE == 'active' ]; then
   USEREXIST=$($MYSQL -u $USER -S $MYSOCK -s -e "select user from mysql.user where user='$DBUSER' and host='$HOST';")
   if [ "$USEREXIST" == "$DBUSER" ]; then
      STATUS="User \"$DBUSER@'$HOST'\" already exists..."; echout "$STATUS"
   else
      STATUS="Creating user \"$DBUSER@'$HOST'\"..."; echout "$STATUS"
      $MYSQL -u $USER -S $MYSOCK -e "create user $DBUSER@'$HOST' identified by '$PWD';"
      if [ $? -eq 0 ]; then
         STATUS="User \"$DBUSER@'$HOST'\" has been created..."; echout "$STATUS"
      else
         STATUS="Error in user creation!!!"; echout "$STATUS"
         PrintExecStatus 1 "$STATUS"
         exit 1
      fi
   fi
else
   STATUS="$HOSTNAME $(basename $0) - MariaDB Service is DOWN!!! Can't create user..."; echout "$STATUS"
   PrintExecStatus 1 "$STATUS"
   exit 1
fi

PrintExecStatus 0 "$STATUS"
exit 0

