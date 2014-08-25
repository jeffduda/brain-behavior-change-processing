#!/bin/sh
# calculate control-label image pairs 
# note: this script assumes first image is "label"

if [ $# -lt 2 ]; then
	progname=`basename $0`
	echo "usage: $progname infile outfile [maskfile]"
	exit 1
fi

infile=$1
outfile=$2

if [ $# -lt 3 ]; then
    maskfile=automask.nii
    rm -f $maskfile
    3dAutomask -prefix $maskfile $infile
else
    maskfile=$3
fi

rm -f $outfile
3dcalc -datum float -prefix $outfile -a $maskfile -b $infile'[0..$(2)]' -c $infile'[1..$(2)]' -expr 'ispositive(a)*100*(c-b)/c'

exit 0
