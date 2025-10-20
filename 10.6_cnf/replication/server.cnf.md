
##############################################################################
# DEPLOYED BY CHEF
# MariaDB database server configuration file for MariaDB 10.6 and above.
#
# Notes:
# 1. Use this config file for MariaDB with replication setup (Tier1/2 Apps)
# 2. Put all non-standard settings / additional application-specific    
#    settings under "Non-standard settings/Application-specific settings"
# 3. Maxscale configuration not included
# 4. Make sure to update server_id per server, i.e. 1&2 (ADC) and 3&4 (TDC)
# 5. Make sure to update gtid_domain_id per server, i.e. ADC servers=1 and TDC servers=2
# 6. Set innodb_buffer_pool_size to 70% of available RAM
#
# Modifed by	: Aries Tayag
# Release Date	: 30 Mar 2021
# 
# All further modifications must be annotated below this line:
#
# 1. 25-May-2021: Added session_track_system_variables (10.4 and above) as per recommendation from MariaDB
# 2. 11-Aug-2021: Added gtid_domain_id=1 for ADC servers, gtid_domain_id=2 for TDC servers
# 3. 19-Aug-2021: Added changes below:
#				  Commented server_audit=FORCE_PLUS_PERMANENT
#				  innodb_log_file_size from 1G to 512M
#				  innodb_io_capacity from 2000 to 400
#    			  innodb_log_files_in_group from 4 to 2
#				  slow_query_log_file from /pmarialogs/mysql/mariadb-slow.log to /pmarialogs/mysql/mariadb_slow.log
#				  general_log_file from /pmarialogs/mysql/mariadb.log to /pmarialogs/mysql/mariadb_general.log
#				  server_audit_file_path from /pmariaaudlogs/audit.log to /pmariaaudlogs/mariadb_audit.log
# 4. 07-Feb-2022: Added changes below:
#				  Commented innodb_log_files_in_group, innodb_buffer_pool_instances (it does nothing now and exists only for compatibility with old my.cnf files)
#				  Commented query_cache_type, query_cache_limit
#				  Set query_cache_size to 0
#				  Commented basedir since we are no longer using tarball installer (using RPM now)
# 5. 10-Mar-2022: Added changes below:
#				  log_queries_not_using_indexes=ON - log queries that don't use indexes to the slow query log
# 6. 22-Mar-2022: Added changes below:
#				  character_set_server=utf8
# 4. 28-Mar-2022: Added changes below:
#				  local_infile=OFF
#				  secure_file_priv=/pmariatmp
#
##############################################################################

[mariadb]

##################################################################
# MariaDB-specific general settings
##################################################################
log_bin=/pmariabinlogs/mariadb-bin
log_bin_index=/pmariabinlogs/mariadb-bin.index
binlog_format=ROW
max_binlog_size=100M
expire_logs_days=7
bind-address=0.0.0.0
port=6033
socket=/pmariatmp/mariadb.6033.sock
general_log=0
general_log_file=/pmarialogs/mysql/mariadb_general.log
#basedir=/pmariadb/mariadb.6033
datadir=/pmariadata
tmpdir=/pmariatmp
autocommit=1
lower_case_table_names=1
log_error=/pmarialogs/mysql/mariadb_error.log
log_warnings=2
slow_query_log=0
slow_query_log_file=/pmarialogs/mysql/mariadb_slow.log
long_query_time=10
log_slow_rate_limit=1000
log_slow_verbosity=query_plan
log_output=FILE
skip_external_locking=1
lc_messages=en_US
lc_messages_dir=/pmariadb/mariadb.6033/share
log_queries_not_using_indexes=ON
character_set_server=utf8
local_infile=OFF
secure_file_priv=/pmariatmp



##################################################################
# Security-specific settings
##################################################################
plugin_load_add=simple_password_check
plugin_load_add=cracklib_password_check
strict_password_validation=ON
simple_password_check_minimal_length=14
default_password_lifetime=90
simple_password_check_digits=1
simple_password_check_letters_same_case=1
simple_password_check_other_characters=1
old_passwords=0



##################################################################
# InnoDB-specific settings
##################################################################
default_storage_engine=InnoDB
innodb_log_file_size=512M
innodb_buffer_pool_size=22G				#set as 70% of available RAM
innodb_log_buffer_size=1G
innodb_file_per_table=1
innodb_open_files=400
innodb_io_capacity=400
innodb_flush_method=O_DIRECT
#innodb_buffer_pool_instances=4
#innodb_log_files_in_group=2
innodb_flush_log_at_trx_commit=2



##################################################################
# Audit-specific settings
##################################################################
plugin_load_add=server_audit
server_audit=FORCE_PLUS_PERMANENT
server_audit_logging=ON
server_audit_mode=0
server_audit_output_type=syslog
server_audit_file_path=/pmariaaudlogs/mariadb_audit.log
server_audit_events=CONNECT,QUERY_DDL,QUERY_DCL
server_audit_file_rotate_size=10000000
server_audit_file_rotate_now=OFF
server_audit_file_rotations=500
server_audit_incl_users=root,mariadbp,repadmin,maxadmin,dsdwgu,dsdscc
server_audit_query_log_limit=1024
server_audit_syslog_facility=LOG_LOCAL6
server_audit_syslog_priority=LOG_INFO
server_audit_syslog_ident=mysql-server-auditing



##################################################################
# Replication-specific settings
##################################################################
server_id=1							##change per server, i.e. 1,2,3,4
gtid_domain_id=1					##set gtid_domain_id=1 for ADC servers, 2 for TDC servers
log_slave_updates=1
gtid_strict_mode=ON
rpl_semi_sync_master_enabled=ON		##will be autoset by promotion/demotion.sql
rpl_semi_sync_slave_enabled=ON		##will be autoset by promotion/demotion.sql
rpl_semi_sync_master_wait_point=AFTER_SYNC
rpl_semi_sync_master_timeout=10000
innodb_flush_log_at_trx_commit=1
sync_binlog=1
sync_master_info=1
sync_relay_log=1
sync_relay_log_info=1
relay_log=/pmariabinlogs/relay-bin
relay_log_index=/pmariabinlogs/relay-bin.index
relay_log_info_file=/pmariabinlogs/relay-bin.info
session_track_system_variables=last_gtid



##################################################################
# Non-standard settings/Application-specific settings
# Note: Below are baseline settings and may need to tune
##################################################################
max_connections=100
connect_timeout=5
wait_timeout=600
thread_cache_size=128
sort_buffer_size=4M
bulk_insert_buffer_size=16M
tmp_table_size=32M
max_heap_table_size=32M
#query_cache_type=2
#query_cache_limit=128K
query_cache_size=0
max_allowed_packet=256M

