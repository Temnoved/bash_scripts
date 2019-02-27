#!/bin/bash

#Constants for the script
#etalon - device ID of current partition
#current_partition - path to partition
declare -r etalon=$(stat -c %d /)
declare -r current_partition="/dev/sda1"

# A function which calculate and show size metrics for this partition
function available_size ()
{
	df -Th $current_partition | grep "sda1" | awk '{ print "| Total size: " $3; print "| Used space: "$4; print "| Available space: "$5}'
}

# A function which find three biggest files only on this partition
# On the first step the function find all files. The next step is deleting
# all writes which have device-ID different than the etalon. After that we
# can find three biggest files in the list with an utility "du".
function big_files ()
{
	IFS=$'\n' arr_files=($(find /* -type f))
	for i in "${!arr_files[@]}"; do [[ $(stat -c %d ${arr_files[i]}) -ne $etalon ]] && unset -v 'arr_files[$i]'; done
	du -h "${arr_files[@]}" | sort -hr | head -n 3
}

# A function which find three biggest dirs only on this partition.
# This function similar a previous ("big_files"), but work with directories.
function big_dirs ()
{
	IFS=$'\n' arr_dirs=($(find /*/ -type d))
	for i in "${!arr_dirs[@]}"; do [[ $(stat -c %d ${arr_dirs[i]}) -ne $etalon ]] && unset -v 'arr_dirs[$i]'; done
	du -h "${arr_dirs[@]}" | sort -hr | head -n 3
}

# A function which aggregate results of work  others functions and create the final output of the script
function main_out ()
{
	echo "*****************************  PARTITION: $current_partition ***********************************************"
	echo "****************************************SIZE*******************************************************"
	available_size
	echo "========================================FILES======================================================"
	echo "Three biggest fiels on the partition:"
	big_files
	echo "The total number of fiels on the partition: ${#arr_files[@]}"
	echo "========================================DIRS======================================================="
	echo "Three biggest dirs on the partition:"
	big_dirs
	echo "The total number of dirs on the partition: ${#arr_dirs[@]}"
	echo "***************************************************************************************************"
}

# Entering a path to a file which save the output of the script
read -p "Enter the path to save the result report: " path_to_save

# The first of all we must check if the path is not empty.
# The second one we have to check existence of the file and if it not exist we create it.
# The last one if the file exist and it available for writing we just write result into the file.
if [[ -z $path_to_save ]]; then
	echo "Sorry the enter is empty"
	exit 1
elif [[ !(-w $path_to_save)  ]]; then
	touch $path_to_save && chmod u+w $path_to_save && main_out > $path_to_save && echo "Create a file of report and writing of the report are success!"
	exit 0
else
	main_out > $path_to_save && echo "Writing of the report is success!"
fi

exit 0
