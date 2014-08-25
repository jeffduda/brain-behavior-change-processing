#!/bin/bash
# ---------------------------------------------------------------
# QA_BOLD.sh - do QA on BOLD 4D Nifti
#   return tab delimited QA metrics file
#
# M. Elliott - 6/2013

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
if [ $2 == "0" ]; then
	resultfile=${indir}/${inroot}.qa
fi
outdir=`dirname $resultfile`

# --- start result file ---
if [ $append -eq 0 ]; then 
    echo -e "modulename\t$0"      > $resultfile
    echo -e "version\t$VERSION"  >> $resultfile
    echo -e "inputfile\t$infile" >> $resultfile
fi

# --- mask ---
if [ "X${maskfile}" = "X" ]; then
    echo "Automasking..." 
    maskfile=${outdir}/${inroot}_qamask.nii
    rm -f $maskfile
    3dAutomask -prefix $maskfile $infile  2>/dev/null
fi

# --- find clipped voxels ---
echo "Counting clipped voxels..."
${EXECDIR}qa_clipcount_v${VERSION}.sh -append $keepswitch $infile $maskfile $resultfile

# --- tSNR  ---
echo "Computing tsnr metrics..."
${EXECDIR}qa_tsnr_v${VERSION}.sh -append $keepswitch $infile $maskfile $resultfile

# --- moco ---
echo "Computing moco metrics..."
${EXECDIR}qa_motion_v${VERSION}.sh -append $keepswitch $infile $resultfile

exit 0
