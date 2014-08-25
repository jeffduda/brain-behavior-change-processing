#!/bin/bash
# ---------------------------------------------------------------
# PREPROC.sh - do standard BOLD preproc on 4D Nifti
#
# M. Elliott - 4/2013

# --- Set AFNI/FSL stuff ---
export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

if [ $# -lt 4 ]; then
	echo "usage: `basename $0` <4Dinput> ndummy do_moco smooth [<outdir>]"
	exit 1
fi

# --- Parse inputs ---
infile=`imglob -extension $1`
SKIP_DUMMY=$2
DO_MOCO=$3
SMOOTH_FWHM=$4
indir=`dirname $infile`
inbase=`basename $infile`
inroot=`remove_ext $inbase`

if [ $# -eq 5 ]; then 
    outdir=$5
else
    outdir=$indir
fi

resfile=$infile # each step will set this as its result file

# remove dummy scans
if [ $SKIP_DUMMY -gt 0 ]; then
    echo "Removing $SKIP_DUMMY dummy scans from $resfile..."
    nreps=`fslval $resfile dim4`
    let "brikn = $nreps-1"
    rm -f $outdir/${inroot}_skipdum.nii
    3dTcat -prefix ${inroot}_skipdum.nii -session $outdir ${resfile}\[${SKIP_DUMMY}..${brikn}\] 2>/dev/null
    resfile=$outdir/${inroot}_skipdum.nii
fi

# moco
if [ $DO_MOCO -eq 1 ]; then
    echo "Moco on $resfile..." 
    mcflirt -in $resfile -o $outdir/${inroot}_mc
    resfile=$outdir/${inroot}_mc.nii
fi

# mask
echo "Masking $resfile..." 
rm -f $outdir/${inroot}_mask.nii 
3dAutomask -prefix $outdir/${inroot}_mask.nii $resfile 2>/dev/null  # 3dAutomask doesn't support "-session", uses full path in "-prefix" !!!

# smooth
if [ $SMOOTH_FWHM -ne 0 ]; then
    echo "Smoothing at $SMOOTH_FWHM mm on $resfile..." 
    rm -f $outdir/${inroot}_smooth.nii 
    3dmerge -1blur_fwhm $SMOOTH_FWHM -doall -session $outdir -prefix ${inroot}_smooth.nii $resfile &>/dev/null
    resfile=$outdir/${inroot}_smooth.nii
fi

exit 0

