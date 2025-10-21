# MariaDB / MySQL Admin Scripts

# Description
A collection of **automation scripts** for **MariaDB** and **MySQL** database administration — including **full backups**, **incremental backups**, 
and **health or performance reports**. These scripts are optimized for **Linux servers** and can be easily integrated with **cron** or any commercial automation tool, such as Chef/Puppet, for automatic execution.

# Requirements
Before running these scripts, make sure your environment meets the following:
   - ✅ MariaDB 10.x / MySQL 5.7+ installed and accessible  
   - ✅ Backup user has **`SELECT`, `LOCK TABLES`, `RELOAD`, `REPLICATION CLIENT`** privileges  
   - ✅ `mysqldump`, `mysql`, and `mysqladmin` available in `$PATH`  
   - ✅ Linux user running the script has permission to write to backup and log directories  
   - ✅ `mail` or `mailx` utility installed for email notifications  

# Environment Variables
Make sure the following are defined either in your environment or inside each script:
   - export MYSQL_USER="backup_user"
   - export MYSQL_PASS="StrongPassword123"
   - export MYSQL_HOST="localhost"
   - export BACKUP_BASE="/var/backups/mysql"

# Directory Structure
Recommended layout for organizing backups, logs, and reports:
   - /var/backups/
   - ├── mysql/
      - ├── full/                # Full database dumps
      - ├── incremental/         # Incremental/binlog backups
      - ├── logs/                # Backup logs
      - └── reports/             # Health and performance reports
   - └── scripts/
      - ├── mysql_full_backup.sh
      - ├── mysql_incremental_backup.sh
      - ├── mysql_health_report.sh
      - └── etc.

# Repository Contents (for updating)

| Script Name                   | Description                                                                                                   |
|-------------------------------|---------------------------------------------------------------------------------------------------------------|
| `mysql_full_backup.sh`        | Performs a **full database dump** (with timestamped logs and email notifications)                             |
| `mysql_incremental_backup.sh` | Executes **incremental or binlog-based backups** every few hours                                              |
| `mysql_health_report.sh`      | Generates a **database health and performance report**, including uptime, slow queries, and table statistics  |
