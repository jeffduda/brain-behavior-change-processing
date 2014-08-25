#!/bin/bash
# ---------------------------------------------------------------
# moco_mprage_parse.sh
#
# Parse the MotionParamters file from the moco_mprage sequence
# outputs a 6-column file with the translation and rotation parameters
#
#   Note: the rotation params in the MotionParamters file are in DEGREES.
#         this program converts them into radians
#
#   Also note: the .par file produced by mcflirt is NOT the same as these params.
#         the translations from mcflirt are the AVERAGE translations, not the actual matrix params.
#
# Created: M Elliott 8/2012
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` <MotionParams_file> <output_file>"
    echo ""
    exit 1
}
if [ $# -lt 2 ]; then
    Usage
fi
mparfile=$1
outfile=$2


# parse for the vals we want
grep "Translation value in x:" $mparfile | tr ":" "\n" | grep -v Translation > tx.1D
grep "Translation value in y:" $mparfile | tr ":" "\n" | grep -v Translation > ty.1D
grep "Translation value in z:" $mparfile | tr ":" "\n" | grep -v Translation > tz.1D
grep "Rotation value in x:" $mparfile | tr ":" "\n" | grep -v Rotation > dx.1D
grep "Rotation value in y:" $mparfile | tr ":" "\n" | grep -v Rotation > dy.1D
grep "Rotation value in z:" $mparfile | tr ":" "\n" | grep -v Rotation > dz.1D

# convert degrees to radians
1deval -a dx.1D -expr 'a/180*3.14159' > rx.1D  
1deval -a dy.1D -expr 'a/180*3.14159' > ry.1D
1deval -a dz.1D -expr 'a/180*3.14159' > rz.1D

# also calculate the sqrt(sum of squares(params))
sqrtfile=`basename $outfile`
sqrtfile=${sqrtfile}.ssq
1deval -a dx.1D -b dy.1D -c dz.1D -d tx.1D -e ty.1D -f tz.1D -expr 'sqrt(a^2+b^2+c^2+d^2+e^2+f^2)' > $sqrtfile

1dcat tx.1D ty.1D tz.1D rx.1D ry.1D rz.1D > $outfile 

rm -f tx.1D ty.1D tz.1D dx.1D dy.1D dz.1D rx.1D ry.1D rz.1D

exit 0

