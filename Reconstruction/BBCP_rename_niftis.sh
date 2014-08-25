#!/bin/bash
# ---------------------------------------------------------------
# BBCP_rename_niftis.sh - Rename Niftis to include TPID in their filenames
#
# Written by M.Elliott 

# -------------------------------

# -------------------------------
function rename_with_TPID
{	
    filefolder=`dirname $1`
    fileroot=`basename $1`

    oldIFS="$IFS"                       # strsplit $fileroot by "_"
    IFS='_'
    parts=( $fileroot )
    IFS="$oldIFS"

    if [ "${parts[0]}" != "${2}" ]; then  # avoid files already prepended with the TPID
        newroot=${2}_${fileroot}
        echo "  renaming $1 -> $newroot"
        mv $1 $filefolder/$newroot
    else
        echo "  ignoring $1 (already exists!)"
    fi
}

# ---------------------------------------------------------------
# --- MAIN routine starts here ---
# ---------------------------------------------------------------
if [ $# -lt 1 ]; then
	echo "usage: $0 <Subjects_dir/>"
	exit 1
fi

# --- run through every ASID/TPID folder ---
cd $1
for sessfolder in $(ls -d [0-9][0-9][0-9][0-9][0-9][0-9]/[a-Z][a-Z][a-Z][0-9][0-9][0-9][0-9][0-9][0-9])
do
    echo "Processing $sessfolder..."
    ASID=`dirname $sessfolder`
    TPID=`basename $sessfolder`

    for filename in $(find $sessfolder -name "*.1D" -print); do
        rename_with_TPID $filename $TPID
    done

    for filename in $(find $sessfolder -name "*.qa" -print); do
        rename_with_TPID $filename $TPID
    done

    for filename in $(find $sessfolder -name "*.log" -print); do
        rename_with_TPID $filename $TPID
    done

    for filename in $(find $sessfolder -name "*.nii" -print); do
        rename_with_TPID $filename $TPID
    done
done


echo "Done."
exit 0
