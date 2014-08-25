#!/bin/bash
# ---------------------------------------------------------------
# force_RPI.sh
#
# Convert a 3D or 4D Nifti to RPI orientation
# 
# ---------------------------------------------------------------

# ---------------------------------------------------------------
Usage() {
    echo ""
    echo "Usage: `basename $0` infile [outfile]"
    echo ""
    exit 1
}

# --- Begin script ---
if [ $# -lt 1 -o $# -gt 2 ]; then
    Usage
fi

# --- get input and output files ---
inroot=`remove_ext $1`
infile=`imglob -extension $1`
if [ "X$infile" == "X" ]; then 
    echo "Neither ${inroot}.nii or ${inroot}.nii.gz exists!"
    exit 1
fi
if [ $# -lt 2 ]; then
    outroot=${inroot}_forcetmp
else
    outroot=`remove_ext $2`
fi

# --- use same output type as input ---
if [ "$infile" == "${inroot}.nii" ]; then
    export FSLOUTPUTTYPE=NIFTI
else
    export FSLOUTPUTTYPE=NIFTI_GZ
fi

# --- get data orientation and obliqueness ---
orient_code=`@GetAfniOrient $infile 2> /dev/null`

# --- convert each case ---    
case $orient_code in    
    RPI)
        echo "Data is already in RPI orientation."
        imcp $inroot $outroot
        ;;
    RAI)
        echo "Converting RAI to RPI orientation."
        fslreorient2std $inroot ${outroot}_LPI
        fslswapdim ${outroot}_LPI -x y z ${outroot}   # This intermediate result has INCONSISTENT data/header!!
        fslorient -swaporient ${outroot}              # now it is correct
        ;;
    RAS)
        echo "Converting RAS to RPI orientation."
        fslreorient2std ${inroot} ${outroot}
        ;;
    RSA)
        echo "Converting RSA to RPI orientation."
        fslreorient2std $inroot ${outroot}_LPI
        fslswapdim ${outroot}_LPI -x y z ${outroot}   # This intermediate result has INCONSISTENT data/header!!
        fslorient -swaporient ${outroot}              # now it is correct
       ;;
    ASR)
        echo "Converting ASR to RPI orientation."
        fslreorient2std ${inroot} ${outroot}
        ;;
    AIL)
        echo "Converting AIL to RPI orientation."
        fslreorient2std ${inroot} ${outroot}
        ;;
    *)
        echo "ERROR: Don't know how to handle orientation code $orient_code."
        exit 1
        ;;
esac  

# --- Overwrite input with result ---   
if [ $# -lt 2 ]; then
    immv $outroot $inroot
fi

# --- Clean up ---
imrm ${outroot}_LPI
exit 0
