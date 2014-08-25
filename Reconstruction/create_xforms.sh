#!/bin/bash
# ---------------------------------------------------------------
# CREATE_XFORMS.SH
#
# Create the rigid-body transformation matrices from a 6-column file of translations (mm) and rotations (radians)
#
# Note 0: If only 3 params are passed in, they are assumed to be rotations (translations will be = 0)
#
# Note 1: This script was designed to use the parameters returned by FSL's "avscale".
#       It then calcualtes the same rigid-body xform provided to "avscale"
#
# Note 2: Calling this with the .par file from mcflirt is NOT correct.
#       the translations in that file are based on the xform found using a different origin than the Nifti origin.
#       (and, also, the mcflirt .par file is: rx,ry,rz,tx,ty,tz)
#
# Note 3: Tortoise returns 14 params, the 1st 6 are the rigid-body params
#       Tortoise returns the motion detected, NOT the params needed to undo the motion
#       This script converts the Tortoise params to match the conventions of FSL (i.e. inverts)
#
# Created: M Elliott 8/2012
# ---------------------------------------------------------------

Usage() {
    echo "" >&2
    echo "Usage: `basename $0` <parfile> <outfile_root>" >&2
    echo "" >&2
    exit 1
}
if [ $# -ne 2 ]; then
    Usage
fi

exec_dir=`dirname "$0"`
parfile=$1
matroot=$2

nvols=`cat $parfile | wc -l`
for (( i=1; i<=$nvols; i++ )) ; do
	
    # get next line from params file
    line=`head -n $i $parfile | tail -n 1`	
        
    # build output filename for matrix
    let count=$i-1
    num=`printf "%4.4d" $count`
    xform_file=${matroot}$num.txt
    echo -n "."

    # create xform matrix from params
    ${exec_dir}/create_xform.sh $line > $xform_file
    if [ $? -ne 0 ]; then exit 1; fi
done

echo ""
exit 0
