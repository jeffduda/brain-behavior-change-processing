#!/bin/bash
# ---------------------------------------------------------------
# get_FSLslicetime.sh
#
# Return a slice time file appropriate for calling FSL's slicetimer routine
#   Use this script's result with "slicetimer --ocustom=<timefile>"
# 
# NOTE: This assumes Siemens interleaved BOLD!!
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` <niftifile> <outfile>"
    echo ""
    exit 1
}

if [ $# -ne 2 ]; then
    Usage
fi

echo "Warning: This routine assumes the images are from a Siemens scanner, and are non-Multiband!"

infile=$1
outfile=$2
echo -n "" > $outfile

# even or odd number of slices?
nz=`fslval $infile dim3`
nztest=$(($nz / 2 * 2))

if [ $nz == $nztest ] ; then    # even number of slices, second slice acquired first...
    echo "$nz slices (even)"
    for ((i=2;i<=$nz;i+=2)); do echo $i >> $outfile; done
    for ((i=1;i<=$nz;i+=2)); do echo $i >> $outfile; done
else
    echo "$nz slices (odd)"
    for ((i=1;i<=$nz;i+=2)); do echo $i >> $outfile; done
    for ((i=2;i<=$nz;i+=2)); do echo $i >> $outfile; done
fi

exit 0
