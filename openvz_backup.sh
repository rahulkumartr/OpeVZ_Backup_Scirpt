#!/bin/bash
# vzdump-backup.sh
# Backup openVZ containers and container configuration
# This script will suspend containers before doing vzdump
# Use with caution.

2>&1

renice 19 -p $$

backup_parent_dir="/Server-Backup"

: > $0.log

#move all the existing backups to old dir, We plan to keep only 2 backups
mv --backup=t -v $backup_parent_dir/*.* $backup_parent_dir/old >> $0.log

echo "Housekeeping $backup_parent_dir - removing older backups (>40 days)" >> $0.log
find $backup_parent_dir/old -name "*.tgz" -mtime +40 -print | xargs rm -vf >> $0.log

#Here list the exclude list of CTID to exclude from backup
exlist=("999" "888")

matched="0"
# Start container backup
for CTID in $( vzlist | awk '{if (NR!=1){print $1}}' )
do
    for e in "${exlist[@]}"
    do
        if [[ "$e" == "$CTID" ]]
        then
            matched="1"
            break ; # Dont take backup
        fi
    done

    if [ $matched = "1" ]  #Pattern 01 match
    then
        CT_name=` vzlist | grep $CTID | awk '{print $5}'` >> /dev/null
        echo "Not Backing up container $CTID - $CT_name" >> $0.log
        matched="0"
        #don't dump
        continue
    fi

    CT_name=` vzlist | grep $CTID | awk '{print $5}'`
    echo "Backing up container $CTID - $CT_name" >> $0.log
    vzdump --compress --dumpdir $backup_parent_dir --tmpdir /Server-Backup/data --suspend $CTID >> $0.log
    echo "$CTID - $CT_name backed up - OK!" >> $0.log
done

echo "Backup tasks completed on `date` - showing directory listing" >> $0.log
ls -lsah $backup_parent_dir >> $0.log

