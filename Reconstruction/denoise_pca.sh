#!/bin/bash
# ---------------------------------------------------------------
# DENOISE_PCA.sh
#
# Use PCA of non-brain voxels to identify and remove "noise" components in 4D data set
# Thanks to J. Magland for the concept
#
# Created: M Elliott 4/2013
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` infile brainmask outfile [ncomp]"
    echo ""
    echo "     ncomp - number of PCA components to use for denoising (default = -10)"   
    echo "           if ncomp < 0 then it is treated as -%nreps to use"
    echo "           (e.g. ncomps = -35 means set ncomps = 35% of nreps)"
    echo ""
    exit 1
}

if [ $# -lt 3 ]; then
    Usage
fi

# --- Set AFNI/FSL stuff ---
export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

# --- parse command line ---
infile=`imglob -extension $1`
maskfile=`imglob -extension $2`
outfile=$3
outfile_root=`remove_ext $outfile`
ncomps=-10
if [ $# -eq 4 ]; then ncomps=$4; fi

# --- Check number of components ---
if [ $ncomps -lt 1 ] ; then # negative param means treat as |%| of nreps
    nreps=`fslval $infile dim4`
    let "ncomps = -1 * $ncomps * $nreps / 100"
fi
echo "Denoising $infile with ncomps = $ncomps"
if [ $ncomps -lt 1 ] ; then echo "Cannot use less than 1 component!"; exit 1; fi

# --- make mask for non-brain voxels from brain mask --- 
fslmaths $maskfile -bin -sub 1 -abs ${outfile_root}_mask

# --- do PCA on noise voxels ---
rm -f $outfile_root.nii $outfile_root.nii*.1D
3dpc -prefix $outfile_root.nii -mask ${outfile_root}_mask.nii -vmean -vnorm -pcsave $ncomps $infile 2>/dev/null
#3dpc -prefix $outfile_root.nii -mask ${outfile_root}_mask.nii -vmean  -pcsave $ncomps $infile 2>/dev/null

# --- remove components from brain voxels ---
rm -f $outfile_root.nii
3dDetrend -prefix $outfile_root.nii -vector $outfile_root.nii.1D $infile 2>/dev/null
rm -f $outfile_root.nii*.1D

exit 0

