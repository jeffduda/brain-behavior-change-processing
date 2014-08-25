#!/bin/bash
# MELLIOTT 8/2012 - compute Jenkinson RMS motion estimates from output of TORTOISE preproc on DTI data
#         
# ---------------------------------------------------------------------

# --- Check input args ---
if [ $# -lt 3 ]; then
	echo "usage: `basename $0` tortoise_transformations_file datafile resultfile"
	exit 1
fi

# --- set some file names ---
exec_dir=`dirname "$0"`
tortoise_file=$1
data_file=$2
output_root=$3

# ---- create an identity matrix for RELRMS and ABSRMS calc below ---
ident_matrix=ident_mat_${RANDOM}.txt
cat << 'EOF' > $ident_matrix
1.000000 0.000000 0.000000 0.000000 
0.000000 1.000000 0.000000 0.000000 
0.000000 0.000000 1.000000 0.000000 
0.000000 0.000000 0.000000 1.000000
EOF

echo "Creating xforms from motion params..."
${exec_dir}/create_xforms.sh $tortoise_file ${output_root}_mat

# replace first matrix with identity, since Tortoise puts coreg to template in first line
mv -f $ident_matrix ${output_root}_mat0000.txt

echo "Calculating RMS metrics from xforms..."
${exec_dir}/ME_rmsdiff.sh ${output_root} $data_file ${output_root}_mat*.txt

exit 0
