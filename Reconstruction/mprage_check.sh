#!/bin/bash
# ---------------------------------------------------------------
# mprage_check.sh - check MPRAGE DICOM file for acq errors
#   specifics: checks for incorrect select of 2D filter 
#              checks for use of Body coil receive

if [ $# -lt 1 ]; then
	echo "usage: $0 file1 [file2] [file3] ..."
	exit 1
fi

tmpfile=/tmp/mprage_check.txt

# run through each file passed in
for file in $@
do
	# echo $file

	dicom_hdr -sexinfo $file > $tmpfile

	! grep --silent "sPreScanNormalizeFilter.ucOn" $tmpfile #>& /dev/null
	goodfilter=$?
	
	! grep --silent "sNormalizeFilter.ucOn" $tmpfile #>& /dev/null
	badfilter=$?
	
	! grep -m 1 "asList\[0\].sCoilElementID.tCoilID" $tmpfile | grep --silent "Body" #>& /dev/null
	bodyreceive=$?


	echo $file $goodfilter $badfilter $bodyreceive
done
	
exit 0
	
