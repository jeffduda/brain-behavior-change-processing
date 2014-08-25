#!/bin/bash
# ---------------------------------------------------------------
# UNENHANCE_DICOMS - find all Enhanced dicoms under a toplevel folder 
#    and convert to "classic" Dicom using dcuncat


# function unehances all Enhanced Dicoms found in provided folder
function unenhance
{
	OCD=$PWD
	cd ${1}

	# run through each file in folder
	for file in *
	do
        # look only at files, not subfolders
		if [ -f ${file} ]; then
			
			# see if file is a dicom
			dicom_hdr $file >& /tmp/dcminfo.txt
			if [ $? == "0" ]; then
				
				# see if Dicom is enhanced
				nechos=`grep "Echo Time" /tmp/dcminfo.txt | wc -l`
				#echo $1/$file $nechos
				if [ $nechos -gt 5 ]; then
					echo "Unehancing $1/$file... "
					dcuncat -unenhance -of $file\_ $file >& /dev/null
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
#for dir in `find $1 -type d -printf \"%P\"\;`
for dir in `find ${1} -type d -printf %P\;`
do
	unenhance ${1}/${dir}
done

echo "Done!"
exit 0
