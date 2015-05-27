# BackupPC_and_SSH_whitelist_for_rsync_and_tar

If you are using SSH and want to do a remote backup (e.g. using BackupPC), you probably have to login as "root". 
This is insecure. In order to allow "root" only the execution of "/usr/bin/rsync" and some of its 
commands, this script may be used. Thus, this script is intended to run on the backup clients.
In fact, this script works like a white list for rsync/tar commands.
