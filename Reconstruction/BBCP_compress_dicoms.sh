#!/bin/bash
# ---------------------------------------------------------------
# compress Dicoms/ folder into a .tgz to save some space

# --- Parse command line ---
if [ $# -ne 1 ]; then
	echo "usage: $0  <Subjects_dir/>"
	exit 1
fi

cd $1
topdir=$PWD # this makes the path absolute (not relative).

for dcmdir in $(ls -d 00*/Images/S*/Dicoms)
do
	if [ ! -e $dcmdir/dicoms.tgz ]; then
        echo "Compressing $dcmdir."
	    cd $dcmdir
	    tar cfz dicoms.tgz *.dcm --remove-files
	    cd $topdir
    else
        echo "$dcmdir already compressed."
    fi

done

echo "Done."
exit 0
