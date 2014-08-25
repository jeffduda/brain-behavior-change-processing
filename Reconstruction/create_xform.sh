#!/bin/bash
# ---------------------------------------------------------------
# CREATE_XFORM.SH
#
# Create the rigid-body transformation matrix from 6 parameters: 3 translations (mm) and 3 rotations (radians)
#
# Note 0: If only 3 params are passed in, they are assumed to be rotations (translations will be = 0)
#
# Note 1: This script was designed to use the parameters returned by FSL's "avscale".
#       It then calculates the same rigid-body xform provided to "avscale"
#
# Note 2: Calling this with the .par file from mcflirt is NOT correct.
#       the translations in that file are based on the xform found using a different origin than the Nifti origin.
#       (and, also, the mcflirt .par file is: rx,ry,rz,tx,ty,tz)
#
# Note 3: Tortoise returns 14 params, the 1st 6 are the rigid-body params
#       Tortoise returns the motion detected, NOT the params needed to undo the motion
#       This script converts the Tortoise params to match the conventions of FSL (i.e. inverts)
#
# Created: M Elliott 9/2012
# ---------------------------------------------------------------

Usage() {
    echo "" >&2
    echo "Usage: `basename $0` tx ty tz rx ry rz" >&2
    echo "  or   `basename $0` rx ry rz  (translations assumed = 0)" >&2
    echo "  or   `basename $0` tx ty tz rx ry rz (+ 8 more ignored Tortoise params)" >&2
    echo "  or   `basename $0` tx ty tz rx ry rz (+ 10 more ignored Eddy params)" >&2
    echo "" >&2
    exit 1
}
if [ $# -ne 3 -a $# -ne 6 -a $# -ne 14 -a $# -ne 16 ]; then
    Usage
fi

# parse args for params 
if [ $# -eq 3 ]; then 
    tx=0  ; ty=0  ; tz=0
    rx=$1 ; ry=$2 ; rz=$3
elif [ $# -gt 5 ]; then 
    tx=$1 ; ty=$2 ; tz=$3
    rx=$4 ; ry=$5 ; rz=$6
fi

# need to handle possible expontial notation!!
tx=`echo "$tx" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`   
ty=`echo "$ty" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`    
tz=`echo "$tz" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`       
rx=`echo "$rx" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`    
ry=`echo "$ry" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`    
rz=`echo "$rz" | awk -F"E" 'BEGIN{OFMT="%10.10f"} {print $1 * (10 ^ $2)}'`       

# If 14 columns - assume this is from Tortoise output!!
if [ $# -eq 14 ]; then   
    tx=`echo "scale=6 ; -1 * $tx" | bc`     # change these signs to match FSL convention
    ty=`echo "scale=6 ; -1 * $ty" | bc` 
    tz=`echo "scale=6 ; -1 * $tz" | bc` 
    #rx=`echo "scale=6 ; -1 * $rx" | bc` 
    #ry=`echo "scale=6 ; -1 * $ry" | bc` 
    #rz=`echo "scale=6 ; -1 * $rz" | bc` 
fi
 
# convert radians to degrees AFNI's cat_matvec
dx=`echo "scale=6 ; -1 * $rx * 180/3.14159" | bc`                             # convert rad->deg (and flip signs!)
dy=`echo "scale=6 ; -1 * $ry * 180/3.14159" | bc`                             
dz=`echo "scale=6 ; -1 * $rz * 180/3.14159" | bc`
cmd="cat_matvec \"-rotate ${dz}I\" \"-rotate ${dy}A\" \"-rotate ${dx}R\" "    # AFNI method to make rotations(degrees)
xfm=`eval $cmd`                                                               # get the xform of just rotations 
set -- $xfm
echo $1   $2     $3 $tx                                                       # add in translations
echo $5   $6     $7 $ty 
echo $9 ${10} ${11} $tz 
echo 0    0      0   1  
    
exit 0
