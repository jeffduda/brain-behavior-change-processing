#!/bin/bash
# ---------------------------------------------------------------
# ME_RMSDIFF
#
# Use FSL's rmsdiff command to compute motion metrics on a list of xform matrices
#
# Created: M Elliott 8/2012
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` <outfile_root> <refvol> matfile1 matfile2 ... matfileN"
    echo ""
    exit 1
}
if [ $# -lt 4 ]; then
    Usage
fi

outroot=$1
absfile=${outroot}_abs.rms
relfile=${outroot}_rel.rms
absmean=${outroot}_abs_mean.rms
relmean=${outroot}_rel_mean.rms

refvol=$2
shift
shift

ident_matrix=ident_mat_${RANDOM}.txt
cat << 'EOF' > $ident_matrix
1.000000 0.000000 0.000000 0.000000 
0.000000 1.000000 0.000000 0.000000 
0.000000 0.000000 1.000000 0.000000 
0.000000 0.000000 0.000000 1.000000
EOF

# compute abs and rel RMS metrics from matrices
rm -f $absfile $relfile
last_mat=$ident_matrix
count=0
for matfile in $@ ; do

    echo -n "."
    # compute absolute RMS displacement from reference volume
    ${FSLDIR}/bin/rmsdiff $ident_matrix $matfile $refvol >> $absfile
 
    # compute relative RMS displacement from previous volume
    if [ $count -gt "0" ] ; then
        ${FSLDIR}/bin/rmsdiff $last_mat $matfile $refvol >> $relfile
    fi
 
    let count=$count+1
    last_mat=$matfile
done

# compute means of abs and rel
nvols=`cat $absfile | wc -l`
abssum=`1dsum $absfile`
relsum=`1dsum $relfile`
echo "scale=6 ; $abssum/$nvols"     | bc > $absmean
echo "scale=6 ; $relsum/($nvols-1)" | bc > $relmean

# clean up
echo ""
rm -f $ident_matrix

exit 0
