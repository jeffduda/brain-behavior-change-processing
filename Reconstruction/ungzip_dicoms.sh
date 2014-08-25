#!/bin/bash
# ---------------------------------------------------------------
# UNGZIP_DICOMS.sh - find all gzipped dicoms under a toplevel folder 
#    and uncompress them
#
# WARNING: Overwrites dicom files with new, uncompressed result!
#
# Written by M.Elliott 


# use gunzip to uncompress all dicoms
function ungzip_dicoms
{	
	OCD=$PWD
	cd ${1}

	shopt -s nullglob # prevents no-file-match problem below

#	echo "looking in $1..."

	# run through each file in folder
	for file in *.dcm.gz
	do		
		echo "gunzipping $1/$file... "
		gunzip -f $file
	done

	cd $OCD
}




# ---------------------------------------------------------------
# --- MAIN routine starts here ---
# ---------------------------------------------------------------

IFS=$';' # this changes what bash thinks is the Internal Field Separator
		 # so whitepace in filenames will not not a problem!!

# --- Parse command line ---
if [ $# -lt 1 ]; then
	echo usage: $0 toplevel_dir
	exit 1
fi

# --- call ungzip subroutine for each subfolder of top one ---
# --- (Note find needs special printf to use IFS above as separator) ---
for dir in `find ${1} -type d -printf %P\;`
do
	ungzip_dicoms ${1}/$dir
done

echo "Done!"
exit 0
