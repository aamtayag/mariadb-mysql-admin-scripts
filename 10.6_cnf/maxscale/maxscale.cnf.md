
##############################################################################
# DEPLOYED BY CHEF
# Maxscale server configuration file for MaxScale 2.5.x and above
#
# Notes: 
# 1. Make sure that passwords in config file are encrypted
#
# Modifed by	: Aries Tayag
# Release Date	: 27 May 2021
# 
# All further modifications must be annotated below this line:
#
#
##############################################################################



###############################################################
## Global parameters
###############################################################

[maxscale]
threads=auto
logdir=/app/maxscale
#log_info=true			#set to True only when troubleshooting


###############################################################
## Server definitions
###############################################################

[Server1]
type=server
address=XXX.XXX.XXX.XXX
port=6033
protocol=MariaDBBackend

[Server2]
type=server
address=XXX.XXX.XXX.XXX
port=6033
protocol=MariaDBBackend


###############################################################
## Monitor definitions
###############################################################

[MariaDB-Monitor]
type=monitor
module=mariadbmon
servers=Server1,Server2
user=maxadmin
password=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
replication_user=repadmin
replication_password=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
monitor_interval=1500
auto_failover=true
auto_rejoin=true
failcount=5
failover_timeout=120s
verify_master_failure=true
master_failure_timeout=30s
enforce_read_only_slaves=true
cooperative_monitoring_locks=majority_of_running
promotion_sql_file=/home1/maxscale/scripts/promotion.sql
demotion_sql_file=/home1/maxscale/scripts/demotion.sql



###############################################################
## Service definitions
###############################################################

[Read-Write-Service]
type=service
router=readwritesplit
servers=Server1,Server2
user=maxuser
password=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
master_reconnection=true
master_failure_mode=error_on_write
transaction_replay=true
slave_selection_criteria=ADAPTIVE_ROUTING
causal_reads=local
causal_reads_timeout=1s
delayed_retry_timeout=120s


[Read-Only-Service]
type=service
router=readconnroute
servers=Server2,Server1
user=maxuser
password=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
router_options=slave


###############################################################
## Listener definitions
###############################################################

[Read-Write-Listener]
type=listener
service=Read-Write-Service
protocol=MariaDBClient
port=6034

[Read-Only-Listener]
type=listener
service=Read-Only-Service
protocol=MariaDBClient
port=6035

