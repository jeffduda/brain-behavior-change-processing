#!/bin/bash
# ---------------------------------------------------------------
# BBCP_qa_studytree.sh - crawl directory structure and QA all NIFTIs
#
# Written by M.Elliott 

# --- Parse command line ---
if [ $# -lt  1 ]; then
	echo "usage: $0 <Subjects_dir/> [overwrite (0 or 1)]"
	exit 1
fi

# --- Overwrite existing QA results? ---
overwrite=0  # default is NO
if [ $# -gt  1 ]; then overwrite=$2; fi

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
		${EXECDIR}protocol2qa.sh BBCP $overwrite $folder/Images/
		if [ $? -ne 0 ]; then exit $?; fi
		let count=count+1
	fi
    fi
done

echo "Processed $count sessions. Done."
exit 0

