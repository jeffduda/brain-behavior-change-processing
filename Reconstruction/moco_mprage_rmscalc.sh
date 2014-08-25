#!/bin/sh
# MELLIOTT 8/2012 - calculate mcflirt motion params from moco_mprage navigators
#
# Since moco_mprage navigators are acquired with prospective motion correction,
#   it means that mcflirt determined motion is actually the RELATIVE subject motion.
# To obtain the absolute subject motion, mcflirt xforms are cummulatively integrated.
#
# Both true ABSOLUTE and RELATIVE RMS motion metric is produced.
# For a sanity check, compare the RELrms result of this script vs. the ABSrms from mcflirt
#   i.e. 1dplot -ynames 'script RELrms' 'mcflirt ABSrms' -one navs_moco_Xrel.rms navs_moco_abs.rms
#
#
# ---------------------------------------------------------------------

CreateIdentMat() {
ident_matrix=ident_mat_${RANDOM}.txt
cat << 'EOF' > $ident_matrix
1.000000 0.000000 0.000000 0.000000 
0.000000 1.000000 0.000000 0.000000 
0.000000 0.000000 1.000000 0.000000 
0.000000 0.000000 0.000000 1.000000
EOF
}

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> [<MotionPars>]"
    exit 1
}

if [ $# -lt 1 -o $# -gt 2 ]; then
    Usage
fi

# build filenames
exec_dir=`dirname "$0"`
infile=$1
inroot=`${FSLDIR}/bin/remove_ext ${infile}`
inroot=`basename $inroot`
outroot1=${inroot}_mcf	      # mcflirt results
outroot4=${inroot}_int1	      # results from integrating mcflirt results
outroot2=${inroot}_seq	      # results computed from sequence MotionParameters file
outroot3=${inroot}_int2	      # results from integrating sequence MotionParameters xform

matdir1=${outroot1}.mat
matdir2=${outroot2}.mat
matdir3=${outroot3}.mat
matdir4=${outroot4}.mat

# Parse prospective moco file produced by moco_mprage sequence
if [ $# -eq 2 ]; then
    echo "Parsing sequence motion params file..."
    mparfile=$2
   ${exec_dir}/moco_mprage_parse.sh $mparfile ${outroot2}.par 
 
    echo "Creating xforms from motion params..."
   ${exec_dir}/create_xforms.sh ${outroot2}.par ${outroot2}_mat

    echo "Calculating RMS metrics from xforms..."
   ${exec_dir}/ME_rmsdiff.sh ${outroot2} $infile ${outroot2}_mat*.txt

    echo "Integrating xforms..."
    CreateIdentMat
    last_mat=$ident_matrix
    for matfile in ${outroot2}_mat*.txt ; do
        echo -n "."
        new_matfile=${matfile}.X
        convert_xfm -omat $new_matfile -concat $matfile $last_mat
        last_mat=$new_matfile
    done
    echo ""

    echo "Calculating RMS metrics from integrated xforms..."
    ${exec_dir}/ME_rmsdiff.sh ${outroot3} $infile ${outroot2}_mat*.txt.X
    
    # put all the matrices in a subfolder
    mkdir $matdir2
    mv -f ${outroot2}_mat*.txt $matdir2
    mv -f ${outroot2}_mat*.txt.X $matdir2
fi

echo "Calling mcflirt on $infile..."
rm -rf $matdir1/
mcflirt -in $infile -out $outroot1 -mats -plots -refvol 0 -rmsabs -rmsrel

echo "Integrating xforms..."
CreateIdentMat
last_mat=$ident_matrix
for matfile in ${outroot1}.mat/MAT_???? ; do
    echo -n "."
    new_matfile=${matfile}.X 
    convert_xfm -omat $new_matfile -concat $matfile $last_mat
    last_mat=$new_matfile
done
echo ""

echo "Calculating RMS metrics from integrated xforms..."
${exec_dir}/ME_rmsdiff.sh ${outroot4} $infile ${outroot1}.mat/MAT_????.X

# clean up
rm -f $ident_matrix

exit 0
