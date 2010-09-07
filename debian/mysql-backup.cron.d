#
# Regular cron jobs for the mysql-backup package
#

# to backup mysql.example.com just do something like:
#0 4	* * *	mysql-backup [ -x /usr/bin/mysql-backup ] && /usr/bin/mysql-backup -c /etc/mysql-backup/mysql.example.com.cnf
