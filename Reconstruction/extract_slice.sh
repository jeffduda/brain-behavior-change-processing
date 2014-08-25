#!/bin/bash
# ---------------------------------------------------------------
# EXTRACT_SLICE.sh
#
# Extract a slice from a 3D set using a 2D image to define the slice
# works on oblique 2D slices using mad tricks!
#
# Created: M Elliott 5/2014
# ---------------------------------------------------------------

# --- Check args ---
if [ $# -lt 3 ]; then
    echo "usage: `basename $0` <3Din> <2Din> <2Dout> <npad>"
    exit 1
fi

# --- Standard startup stuff ---
OCD=${PWD}; EXECDIR=`dirname $0`; cd ${EXECDIR}; EXECDIR=${PWD}; cd ${OCD}   # get absolute path to this script
source ${EXECDIR}/qa_preamble.sh

# --- Build an identity matrix in ITK format ---
ident_matfile="/tmp/ident_itk.txt"
cat << EOF > $ident_matfile
#Insight Transform File V1.0
# Transform 0
Transform: MatrixOffsetTransformBase_double_3_3
Parameters: 1 0 0 0 1 0 0 0 1 0 0 0 
FixedParameters: 0 0 0	
EOF

# --- Parse args ---
volfile=`imglob -extension $1`

slicefile=`imglob -extension $2`
indir=`dirname $slicefile`
inbase=`basename $slicefile`
inroot=`remove_ext $inbase`

outfile=$3
outdir=`dirname $outfile`
outbase=`basename $outfile`
outroot=`remove_ext $outbase`
outfile=${outdir}/${outroot}.nii # this makes sure there's a .nii on the outfile

if [ $# -gt 3 ]; then
    npad=$4
else
    npad=5
fi

# --- pad extra slice onto the 2D slice to make it a slab (i.e. a volume) ---
echo "Padding $slicefile with $npad extra slices..."
padnum=`printf "%2.2d" $npad`
padfile=${indir}/${inroot}_pad${padnum}.nii
${EXECDIR}/pad_nifti.sh $slicefile $npad $padfile

# --- extract matching slab from 3D volume ---
echo "Extracting slab from $volfile..."
slabfile=${outdir}/${outroot}_slab${padnum}.nii
antsApplyTransforms -i $volfile -r $padfile -o $slabfile -t $ident_matfile

# --- peel off bottom slice ---
echo "Peeling off bottom slice to $outfile..."
c3d $slabfile -slice z 0 -o $outfile # this makes sure there's a .nii on the outfile

# --- clean up ---
if [ $keep -eq 0 ]; then 
    rm -f $padfile $slabfile
fi
rm -f $ident_matfile    # should always delete this so next caller doesn't permissions to overwrite it
exit 0
