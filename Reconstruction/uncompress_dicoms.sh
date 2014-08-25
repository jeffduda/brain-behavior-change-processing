#!/bin/bash
# ---------------------------------------------------------------
# UNCOMPRESS_DICOMS.sh - find all dicoms under a toplevel folder 
#    and convert to uncompressed format
#
# WARNING: Overwrites dicom files with new, uncompressed result!
#
# Written by M.Elliott 


# use gdcmconv to uncompress all dicoms
function uncomp
{
	tmpfile=temp_uncomp.dcm
	rm -f $tmpfile
	
	OCD=$PWD
	cd ${1}

	# run through each file in folder
	for file in *
	do
        # look only at files, not subfolders
		if [ -f "${file}" ]; then
			
			# see if file is a dicom
			dcmftest $file >& /dev/null
			if [ $? == "0" ]; then
				echo "Converting $1/$file... "
				gdcmconv --raw $file $tmpfile	
				  if [ $? == "0" ]; then
				    mv -f $tmpfile $file
				  fi
			fi
		fi
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

# --- call unenhance subroutine for each subfolder of top one ---
# --- (Note find needs special printf to use IFS above as separator) ---
for dir in `find ${1} -type d -printf %P\;`
do
	uncomp ${1}/$dir
done

echo "Done!"
exit 0
