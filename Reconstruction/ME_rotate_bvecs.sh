#!/bin/bash
# ---------------------------------------------------------------
# ME_ROTATE_BVECS.SH
# Rotate a bvecs file using the motion pars file returned by FSL's eddy
#   Also works for motion pars from ME_eddy_correct.sh
#   Also works for rotation pars (i.e. "ec_rot.txt") from jenkinson_ecclog_parse.sh
#
# Modified from fdt_rotate_bvecs.sh
#
# See create_xforms.sh for comments about the motionpar file 
#
# Created: M Elliott 5/2014
# ---------------------------------------------------------------


Usage() {
    echo "" >&2
    echo "Usage: `basename $0` <original bvecs> <rotated bvecs> <motionpar file>" >&2
    echo "" >&2
    exit 1
}
if [ $# -ne 3 ]; then
    Usage
fi

exec_dir=`dirname "$0"`
bvec_in=$1
bvec_out=$2
parfile=$3

# -- make transform matrices from par file ---
matroot=`tmpnam`    
#echo $matroot
${exec_dir}/create_xforms.sh $parfile $matroot
if [ $? -ne 0 ]; then exit 1; fi

# --- apply each rotation to bvec ---
rm -f $bvec_out
ii=1
for matfile in ${matroot}*.txt ; do
    #echo $matfile

    # --- This block of code take from fdt_rotate_bvecs.sh ---
    m11=`avscale $matfile | grep Rotation -A 1 | tail -n 1| awk '{print $1}'`
    m12=`avscale $matfile | grep Rotation -A 1 | tail -n 1| awk '{print $2}'`
    m13=`avscale $matfile | grep Rotation -A 1 | tail -n 1| awk '{print $3}'`
    m21=`avscale $matfile | grep Rotation -A 2 | tail -n 1| awk '{print $1}'`
    m22=`avscale $matfile | grep Rotation -A 2 | tail -n 1| awk '{print $2}'`
    m23=`avscale $matfile | grep Rotation -A 2 | tail -n 1| awk '{print $3}'`
    m31=`avscale $matfile | grep Rotation -A 3 | tail -n 1| awk '{print $1}'`
    m32=`avscale $matfile | grep Rotation -A 3 | tail -n 1| awk '{print $2}'`
    m33=`avscale $matfile | grep Rotation -A 3 | tail -n 1| awk '{print $3}'`

    X=`cat $bvec_in | awk -v x=$ii '{print $x}' | head -n 1 | tail -n 1 | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' `
    Y=`cat $bvec_in | awk -v x=$ii '{print $x}' | head -n 2 | tail -n 1 | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' `
    Z=`cat $bvec_in | awk -v x=$ii '{print $x}' | head -n 3 | tail -n 1 | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}' `
    rX=`echo "scale=7;  ($m11 * $X) + ($m12 * $Y) + ($m13 * $Z)" | bc -l`
    rY=`echo "scale=7;  ($m21 * $X) + ($m22 * $Y) + ($m23 * $Z)" | bc -l`
    rZ=`echo "scale=7;  ($m31 * $X) + ($m32 * $Y) + ($m33 * $Z)" | bc -l`

    if [ "$ii" -eq 1 ];then
	    echo $rX > $bvec_out; echo $rY >> $bvec_out; echo $rZ >> $bvec_out
    else
	    cp $bvec_out $matroot # $matroot is a temp file name we can use
	    (echo $rX;echo $rY;echo $rZ) | paste $matroot - > $bvec_out
    fi

    let "ii+=1"
done

rm -f ${matroot}*
exit 0
