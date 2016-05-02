---
title: mysql-backup
section: 1
header: User manual
footer: mysql-backup
author:
  - Sébastien Gross  &lt;seb•ɑƬ•chezwam•ɖɵʈ•org&gt; (**@renard_0**)
date: 2016-05-02 14:58:20
adjusting: b
hyphenate: yes
---

# NAME

mysql-backup - Backup MySQL databases.

# SYNOPSIS

mysql-backup [ options ] [ --dump | --snapshot ]

# DESCRIPTION

*mysql-backup* performs daily, weekly and monthly backup of MySQL databases.
Features:

- Backup multiple databases
- Compress backup files
- Backup remote servers
- Rotate backups
- more...

# ARGUMENTS

## Options

-c CONFIG, --config CONFIG
: A configuration file to use instead of default one. This option allows
  different configuration for different MySQL servers.

-v, verbose
: Run in verbose mode.

-h, --help
: Show a short help screen.

--dry-run
: Run in *dry-run* mode, do not perform any action.

--dump, -d
: Do a *mysqldump* backup.

--snapshot, -s
: Perform a binary backup using *lvm* snapshot.


NOTE: To restore a LVM snapshot you just need to untar the archive.


# CONFIGURATION FILE

## Default configuration

*mysql-backup* looks for a default configuration file in that order:

- `/etc/mysql-backup/default.cnf`
- `~/.mysql-backup.cnf`
- `./.mysql-backup.cnf`

If no default configuration file is found, default hard-coded values would
be used.

## Specific configuration file

In addition of the default configuration, a specific configuration file can
be used (with the `--conf` option).

### General options

BACKUP_DIR
: Where the backups files would be stored. A generic backup file schema is:

    \<BACKUP_DIR>/\<host>/\<binary|dump>/\<daily|weekly|monthly>/\<base>_YYYY-MM-DD.sql[.\<COMPRESSION_EXTENSION>]

### MySQL options

DATABASES
: Databases to backup. If this value is set to *ALL* then all databases
  would be backuped.  *mysql-backup* would determine the database using the
  "SHOW DATABASES" query.

IGNORE_DATABASES
: A list of database to ignore during backup. By default,
  *information_schema* and *performance_schema* are ignored.

In addition to that option all mysql(1) and mysqldump(1) options are also
recognized as long as dash (`-`) are changed to underscore (`_`).

NOTE: However some options are not recognized: *help*, *pipe*, *table*,
*version*, *databases*, *ignore-table*, *ssl*, *execute*.

EXAMPLE: This is the default MySQL configuration:

    batch=1
    skip_column_names=1
    quote_names=1
    opt=1
    add_drop_database=1


EXAMPLE: If you use *mysqld_multi* you can defined a common complex
configuration file (ie. */etc/mysql-backup/\_\_multi-defaults.inc*) such as:

    BACKUP_DIR=/var/backups/mysql/
     HOST=articles${_instance}
    TARGET_MOUNT=/tmp/$HOST-bck
    LVM_SNAPSHOT_SIZE="100G"
    mysql_instance=mysqld${_instance}
    proto=SOCKET
    socket=/var/run/mysqld/mysqld_${_instance}.sock
    tar_opts=""
    mysqladmin_extra_file=/etc/mysql/debian_${_instance}.cnf
    user=$(${my_print_defaults} -c ${mysqladmin_extra_file} client | awk -F= '{if($1~/^--user$/){print $2}}')
    password=$(${my_print_defaults} -c ${mysqladmin_extra_file} client | awk -F= '{if($1~/^--password$/){print $2}}')

and an instance specific configuration in (*/etc/mysql-backup/instance00.cnf*):

    instance=00
    source /etc/mysql-backup/__multi-defaults.inc

And a cron such as:

    01 00 * * * root mysql-backup -c /etc/mysql-backup/instance00.cnf --snapshot

### Archive options

COMPRESSION
: The tool to use for compression. Currently *gzip*, *pigz*, *bzip2* and
  *xz* are recognized. If compression if not known then no compression would
  be used.

NOTE: *gzip* generates bigger files than the others but needs less CPU time.

COMPRESSION_OPTS
: Options to pass to the compression tool.

DAILY_RETENTION
: How many days a daily backup should be kept. By default daily archives are
  kept 7 days.

WEEKLY_RETENTION
: How many days a weekly backup should be kept. By default weekly archives are
  kept 35 days (5 weeks).

MONTHLY_RETENTION
: How many days a monthly backup should be kept. By default monthly archives
  are kept 365 days (12 months).

WEEKLY_DAY
: Which day weekly backup are done (0..6, 0 is Sunday).

MONTHLY_DAY
: Which day monthly backup are done (00..31).

HOST
: Name of the host to backup for logging purposes.


NOTE: This is not the mysql host to backup (use "host" in lowercase for
that).

### LVM Options

LVM_EXT
: Extension for the LVM snapshot (Default: "_bkp") that would be added to
  the current LVM volume name.

LVCREATE_OPTS
: Options to pass to lvcreate(1) when doing LVM snapshot (Default:
  "--chunksize=256").

LVREMOVE_OPTS
: Options to pass to lvremove(1) when purging a snapshot (Default: "-f").

TARGET_MOUNT
: Where to mount the LVM snapshot before archiving the data (Default:
  "/tmp/mysql-snapshot").

### Hooks

Hooks are scripts that can be run via run-parts(8). Each hook parameter
consists of a directory path suitable for run-parts(8).

See run-parts(8) for further information on how hooks are run.

See *HOOK DETAILS* section for details.

# ARCHIVE PROCEDURE

Every day backups are done in the *daily* directory. On *WEEKLY_DAY* the
daily backup is hard linked to the *weekly* directory (the same is done for
monthly backups on *MONTHLY_DAY* and *monthly* directory).

After that archives older that *DAILY_RETENTION*, *WEEKLY_RETENTION* and
*MONTHLY_RETENTION* are removed from their specific directories.

This system keeps space on the backup server by the use of hard links.

NOTE: This only works if all backups are in a single partition.


## How is this done?

First *mysql-backup* generate a *LVM* snapshot of the *mysql* you want to
backup. During that snapshot creation the replication is stopped, the tables
are locked ("FLUSH TABLES WITH READ LOCK"). Then the current replication
status (for both master and slave) are dumped into mysql *datadir* in files
*show-master-status* and *show-slave-status*.

For each kind of backup (snapshot or dump) an other *mysqld* instance is
started using the new *lvm* snapshot as *datadir*. This will ensure the
rebuild of innodb journal and indexes. Then the archive process is run
(*mysqldump* for dump and *tar* for snapshot).

NOTE: For big databases you'd better want to use a snapshot backup since the
archive process would be faster and the restoration either.

Once every backup are done, the *lvm* snapshot is removed.


# Restoration procedure

For binary snapshot you only need to untar the archive on a new server to
create a clone.

For dump backups, you need to replay every database files, such as:

    zcat base_YYY-MM-DD.sql.gz | mysql -


# HOOKS DETAILS

## Dump hooks

pre_dump_backup_hook
: Hook to be run before the dump backup process really starts.

post_dump_backup_hook
: Hook to be run after the dump backup process is done.

pre_dump_restore_hook
: Hook to be run before the dump restore process really starts.

post_dump_restore_hook
: Hook to be run after the dump restore process is done.


NOTE: In addition hook names could be postfixed with a database name. This
means a hook could be defined for a specific database.

EXAMPLE: *post_dump_backup_hook_a_database* is ran before *a_database* would
be backuped.

## Snapshot hooks

pre_snapshot_backup_hook
: Hook to be run before a snapshot really stats.

post_snapshot_backup_hook
: Hook to be run when a snapshot is done.

pre_snapshot_backup_lvm_snaphost_hook
: Hook to be run before the LVM snapshot is started.

post_snapshot_backup_lvm_snaphost_hook
: Hook to be run after the LVM snapshot is done.

pre_snapshot_backup_archive_hook
: Hook to be run before the archive process is started.

post_snapshot_backup_archive_hook
: Hook to be run after the archive process is done.

NOTE: There is no database postfix for snapshot hooks since there would be
nonsense.

# SEE ALSO

- mysql(1)
- mysqldump(1)
- gzip(1), bzip2(1), xz(1)
- run-parts(8)

# HISTORY

## Version XX

- Add PID to log entries.
- Enhance log messages.
- Enhance launch of temporary mysql instance.
- Add support for [pigz](http://zlib.net/pigz/).

## Version 2.2

2015-02-02:

- Wait if blocked queries are longer than 10s.

## Version 2.0

2014-03-06:

- rewrite the core application.
- bump to version 2.0


## Version 1.9

2012-06-04:

- Add replication information for dumps
- Add snapshot option
- Add *LVCREATE_OPTS*

## Version 1.0

2010-09-06:

  First release.

# BUGS

No time to include bugs, command actions might seldom lead astray
user's assumption.

# COPYRIGHT

Copyright © 2010-2014 Sébastien Gross \<seb•ɑƬ•chezwam•ɖɵʈ•org>.

Released under [GNU GPL version 3 or higher](http://www.gnu.org/licenses/gpl.html).
