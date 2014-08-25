#!/bin/csh
# run mprage-qa script on all passed in structural Nitftis
#
# e.g. batch_mprage_qa */data/images/mprage_Series*/MPRAGE_TI1100_ipat2.nii.gz

if ($#argv < 1) then
	echo "usage: $0 file(s)"
	exit 1
endif

foreach file ($argv[*])	# loop over all files
	
	~/programs/scripts/mprage_qa.sh $file results.txt >& /dev/null
	
	set res = `cat results.txt`
	
	echo $file $res[3] $res[6] $res[9] $res[12] $res[15] $res[18] $res[21] $res[24] $res[27]
		
end

exit 0			# Done
