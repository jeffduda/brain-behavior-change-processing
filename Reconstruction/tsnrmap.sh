#!/bin/bash
# ---------------------------------------------------------------
# TSNRMAP.sh - compute tSNR map from 4D Nifti
#
# M. Elliott - 4/2013

# --- Set AFNI/FSL stuff ---
export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

SKIP_DUMMY=0
SMOOTH_FWHM=4	# (mm)

do_denoise=1

if [ $# -lt 2 ]; then
	echo "usage: `basename $0` 4Dinput outfile"
	exit 1
fi

# --- Figure out path to other scripts in same place as this one ---
EXECDIR=`dirname $0`
if [ "X${EXECDIR}" != "X" ]; then
    OCD=$PWD; cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD # makes path absolute
fi

# --- Parse inputs ---
infile=`imglob -extension $1`
outfile=$2
infile_root=`remove_ext $infile`
outfile_root=`remove_ext $outfile`

# remove dummy scans
if [ $SKIP_DUMMY -gt 0 ]; then
    echo "Skipping $SKIP_DUMMY dummy scans in $infile..."
    nreps=`fslval $infile dim4`
    let "brikn = $nreps-1"
    rm -f ${infile_root}_skipdum.nii
    3dTcat -prefix ${infile_root}_skipdum.nii ${infile}\[${SKIP_DUMMY}..${brikn}\]
    resfile=${infile_root}_skipdum.nii
else
    resfile=$infile
fi

# moco
echo "Moco on $resfile..." 
mcflirt -in $resfile -o ${infile_root}_mc
resfile=${infile_root}_mc.nii

# mask
echo "Masking $resfile..." 
rm -f ${infile_root}_mask.nii
3dAutomask -prefix ${infile_root}_mask.nii $resfile 2>/dev/null

# smooth
if [ $SMOOTH_FWHM -ne 0 ]; then
    echo "Smoothing at $SMOOTH_FWHM mm on $resfile..." 
    rm -f ${infile_root}_smooth.nii 
    3dmerge -1blur_fwhm $SMOOTH_FWHM -doall -prefix ${infile_root}_smooth.nii $resfile &>/dev/null
    resfile=${infile_root}_smooth.nii
fi

# --- Denoise ---
if [ $do_denoise -eq 1 ]; then
    echo "De-noising $resfile..."
    ${EXECDIR}denoise_pca.sh $resfile ${infile_root}_mask ${infile_root}_denoise -10
    resfile=${infile_root}_denoise
fi

# mean and std
fslmaths $resfile -Tmean ${infile_root}_mean -odt float
fslmaths $resfile -Tstd  ${infile_root}_std  -odt float

# tsnr
fslmaths ${infile_root}_mean -mas ${infile_root}_mask -div ${infile_root}_std ${outfile_root} -odt float

exit 0

