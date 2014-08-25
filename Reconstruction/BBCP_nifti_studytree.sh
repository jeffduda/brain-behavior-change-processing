#!/bin/bash
# ---------------------------------------------------------------
# BBCP_nifti_studytree.sh - crawl directory structure and build all NIFTIs
#
# Written by M.Elliott 

# --- Parse command line ---
if [ $# -ne 1 ]; then
	echo "usage: $0 <Subjects_dir/>"
	exit 1
fi

# --- Figure out path to other scripts in same place as this one ---
EXECDIR=`dirname $0`
if [ "X${EXECDIR}" != "X" ]; then
    OCD=$PWD; cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD # makes path absolute
fi

# Find all dirs and look for an Images/ subdir
count=0
cd $1
shopt -s nullglob # prevents no-file-match problem below
for folder in $(ls -d 00*)
do	
    if [ $folder != "." ]; then	
	if [ -d $folder/Images ]; then
		echo "------------------------------------------------------------------------------------------"
		echo "Processing Images/ under for $folder/"
		echo "------------------------------------------------------------------------------------------"
		${EXECDIR}protocol2nifti.sh BBCP $folder/Images/
		if [ $? -ne 0 ]; then exit $?; fi
		let count=count+1
	fi
    fi
done

echo "Processed $count sessions. Done."
exit 0

