#!/bin/bash
# ---------------------------------------------------------------
# RMSERR
#
# Compute RMS displacement difference between 2 sets of xforms
#
# NOTE: mcflirt and flirt return the xforms needed to correct motion, not the xform of the motion
#       i.e. the matrix inverse of the actual motion
#
#       Tortoise returns the matrix of the actual motion
#       i.e. NOT the inverse!
#
#   therefor, this script inverts the second set of xforms
#
# Created: M Elliott 9/2012
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` <outfile_root> <refvol> matfileA1 matfileA2 ... matfileAn matfileB1 matfileB2 ... matfileBn"
    echo ""
    exit 1
}
if [ $# -lt 4 ]; then
    Usage
fi

outroot=$1
absfile=${outroot}_abs.rms
absmean=${outroot}_abs_mean.rms
refvol=$2
inv_matrix=invmat_${RANDOM}.txt
shift
shift

xforms=($@)
let "N = ${#xforms[@]}/2"

# compute abs and rel RMS metrics from matrices
rm -f $absfile
for (( i=0; i<$N; i++ )) ; do
    echo -n "."
    let "j = $i + $N"
#    echo ${xforms[$i]} ${xforms[$j]}
    ${FSLDIR}/bin/convert_xfm -omat $inv_matrix -inverse ${xforms[$j]}
#    ${FSLDIR}/bin/rmsdiff ${xforms[$i]} ${xforms[$j]} $refvol >> $absfile
    ${FSLDIR}/bin/rmsdiff ${xforms[$i]} $inv_matrix $refvol >> $absfile
done

# compute means of abs and rel
nvols=`cat $absfile | wc -l`
abssum=`1dsum $absfile`
echo "scale=6 ; $abssum/$nvols"     | bc > $absmean

echo ""
rm -f $inv_matrix

exit 0
