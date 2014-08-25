#!/bin/bash
# ---------------------------------------------------------------
# QA_PCDENOISE.sh
#
# Use PCA of non-brain voxels to identify and remove "noise" components in 4D data set
# Thanks to J. Magland for the concept
#
# Created: M Elliott 4/2013
# ---------------------------------------------------------------

# --------------------------
Usage() {
	echo "usage: `basename $0` [-append] [-keep] <4Dinput> [<maskfile>] <resultfile>"
    exit 1
}
# --------------------------

# --- Perform standard qa_script code ---
source qa_preamble.sh

# --- Parse inputs ---
if [ $# -lt 2 -o $# -gt 3 ]; then Usage; fi
infile=`imglob -extension $1`
indir=`dirname $infile`
inbase=`basename $infile`
inroot=`remove_ext $inbase`
maskfile=""
if [ $# -gt 2 ]; then
    maskfile=`imglob -extension $2`
    shift
fi
resultfile=$2

# --- start result file ---
if [ $append -eq 0 ]; then 
    echo -e "modulename\t$0"      > $resultfile
    echo -e "version\t$VERSION"  >> $resultfile
    echo -e "inputfile\t$infile" >> $resultfile
fi

# --- mask ---
if [ "X${maskfile}" = "X" ]; then
    echo "Automasking..." 
    maskfile=${indir}/${inroot}_mask.nii
    rm -f $maskfile
    3dAutomask -prefix $maskfile $infile  2>/dev/null
fi

# --- make mask for non-brain voxels from brain mask --- 
fslmaths $maskfile -bin -sub 1 -abs ${indir}/${inroot}_nonbrain_mask

# --- do PCA on noise voxels ---
nreps=`fslval $infile dim4`
ncomps=10
imrm ${indir}/${inroot}_pca
#rm -f ${indir}/${inroot}_pca.nii*.1D
#3dpc -prefix ${indir}/${inroot}_pca.nii -mask ${indir}/${inroot}_nonbrain_mask.nii -vmean -vnorm -pcsave $ncomps $infile #2>/dev/null
3dpc -prefix ${indir}/${inroot}_pca -mask ${indir}/${inroot}_nonbrain_mask.nii -vmean -vnorm -eigonly $infile #2>/dev/null

# --- remove components from brain voxels ---
#rm -f $outfile_root.nii
#3dDetrend -prefix $outfile_root.nii -vector $outfile_root.nii.1D $infile 2>/dev/null
#rm -f $outfile_root.nii*.1D

exit 0

