#!/bin/bash
# ---------------------------------------------------------------
# BBCP_translate_studytree.sh - translate BBCP study tree from BBLID/subjname to BBCP ASID and TPID codes
#
# Written by M.Elliott 

# -------------------------------
function create_dir
{	
	if [ ! -d ${1} ]; then 
		echo "   Creating $1"
		mkdir $1
	fi
}

# ---------------------------------------------------------------
# --- MAIN routine starts here ---
# ---------------------------------------------------------------

# --- Parse command line ---
if [ $# -lt 1 ]; then
	echo "usage: $0 <Subjects_dir/>"
	exit 1
fi

translate_file="/jet/bbcp/Studies/translation_tables/BBL_to_BBCC_initial_23March2014.txt"
if [ ! -e $translate_file ]; then
    echo "ERROR: Cannot find $translate_file."
    exit 1
else
    echo "Using $translate_file to translate subject/session folders"
fi

cd $1

# --- run through each entry in the translation table and look for match ---
while read p; do
    line=($p)
    infolder=${line[0]}
    asid=${line[1]}
    tpid=${line[2]}
    
    if [ -d ${infolder} ]; then
        echo "Matched $infolder"
        create_dir $asid
        create_dir $asid/Info
       
        echo "   Renaming $infolder -> $asid/$tpid"
        if [ -d $asid/$tpid ]; then
            echo "   ERROR: $asid/$tpid already exists!! This should NOT happen!"
            exit 1
        else
            mv $infolder $asid/$tpid
            if [ $? -ne 0 ]; then
                echo "   ERROR: rename failed!"
                exit 1
            fi
            echo $infolder > $asid/$tpid/Info/BBL_subject_session.txt  # write the BBLID info for safety checking later
        fi
    fi

done < $translate_file



echo "Done."
exit 0

