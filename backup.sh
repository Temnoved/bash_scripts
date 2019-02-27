#!/bin/bash

# If the script doesn't find itself in the crontab for current user, it writes
# itself in a list of execution to all work days at 22:05
if [[ -z $(crontab -l 2>/dev/null -u "${USER}" | grep "$0") ]]; then
	(crontab -l 2>/dev/null; echo "05 22 * * 1-5 $0") | crontab -
fi

# Constans for the script
# backup_source - path to directory which will be archived
# backup_target - a path to a directory in which will be saved the archive
# backup_base_name - a constant part of name all archives
declare -r backup_source="/home/alex/pict"
declare -r backup_target="/home/alex/bin/backupresult"
declare -r backup_base_name="backup_from_pict_"

# Creating an archive with "bzip2", with append date to the name 
find ${backup_source}/* | tar -cvjf ${backup_target}/${backup_base_name}$(date +"%d.%m.%G_%H-%M-%S").tar.bz2 -T -

# Check a number of archives in the directory. If the amount more that five
# the script will destroy a oldest of them (one or more).
while [[ $(find ${backup_target} -type f | wc -l) -gt 5 ]]; do
	rm -rf ${backup_target}/$(ls -rt ${backup_target} | head -1)
done

exit 0
