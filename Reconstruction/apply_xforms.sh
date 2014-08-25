#!/bin/bash
# MELLIOTT 8/2012 - apply 4x4 xform matrices to 4D nifti volume
#         
# ---------------------------------------------------------------------

# --- Check input args ---
if [ $# -lt 2 ]; then
	echo "usage: `basename $0` input-4Dfile outfile_root matfile1 matfile2 ... matfileN"
	exit 1
fi

infile=$1
outroot=$2
shift
shift

echo "Splitting 4D volume into 3d volumes..."
fslsplit $infile ${outroot}_tmp
#full_list=`${FSLDIR}/bin/imglob ${outroot}_tmp????.*`
split_list=( ${outroot}_tmp????.* )

echo "Applying xforms to 3D volumes..."
count=0
for matfile in $@ ; do

    echo -n "."
    num=`printf "%4.4d" $count`
    outfile=${outroot}_xfm$num
    ${FSLDIR}/bin/flirt -applyxfm -init $matfile -in ${split_list[$count]} -ref ${split_list[$count]} -out $outfile -interp trilinear

    let count=$count+1
done
echo ""

echo "Merging xformed result into 4D volume..."
rm -f ${split_list[@]}
xfm_list=( ${outroot}_xfm????.* )
fslmerge -t $outroot ${xfm_list[@]}
rm -f ${xfm_list[@]}

exit 0
