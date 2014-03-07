#
# Regular cron jobs for the mysql-backup package
#

# uncomment to prevent from sending mail (not recommended).
# MAILTO=""

PATH=/usr/sbin:/usr/bin:/sbin:/bin

# to backup mysql.example.com just do something like:
#0 4	* * *	mysql-backup [ -x /usr/bin/mysql-backup ] && /usr/bin/mysql-backup -c /etc/mysql-backup/mysql.example.com.cnf --dump

# 35 9 * * * root /usr/bin/mysql-backup --snapshot --dump