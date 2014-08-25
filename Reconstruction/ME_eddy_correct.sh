#!/bin/bash
# MELLIOTT 3/2012 - modified to produce RELRMS and ABSRMS motion estimates
#          6/2012 - added extraction of rigid-body component from Affine xform
#                   (appears to make RMS motion estimates even bigger! ??)
#	8/2912 - added choice of Flirt cost function
#
#   The results from the AFFINE xform produces exactly the same result at jenkinson_ecclog_parse.sh,
#       which is what Mark Jenkinsomn posted to the FSL message board.
#
# ---------------------------------------------------------------------

#   Copyright (C) 2004-8 University of Oxford
#
#   Part of FSL - FMRIB's Software Library
#   http://www.fmrib.ox.ac.uk/fsl
#   fsl@fmrib.ox.ac.uk
#   
#   Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
#   Imaging of the Brain), Department of Clinical Neurology, Oxford
#   University, Oxford, UK
#   
#   
#   LICENCE
#   
#   FMRIB Software Library, Release 4.0 (c) 2007, The University of
#   Oxford (the "Software")
#   
#   The Software remains the property of the University of Oxford ("the
#   University").
#   
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software,
#   or that it will be suitable for any particular purpose or for use
#   under any specific conditions. Furthermore, the University disclaims
#   all responsibility for the use which is made of the Software. It
#   further disclaims any liability for the outcomes arising from using
#   the Software.
#   
#   The Licensee agrees to indemnify the University and hold the
#   University harmless from and against any and all claims, damages and
#   liabilities asserted by third parties (including claims for
#   negligence) which arise directly or indirectly from the use of the
#   Software or the sale of any products based on the Software.
#   
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University. The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product. You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#   
#   You are not permitted under this Licence to use this Software
#   commercially. Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the
#   Software or any derivative of it for research with the final aim of
#   developing software products for sale or license to a third party or
#   (3) use of the Software or any derivative of it for research with the
#   final aim of developing non-software products for sale or license to a
#   third party, or (4) use of the Software to provide any service to an
#   external organisation for which payment is received. If you are
#   interested in using the Software commercially, please contact Isis
#   Innovation Limited ("Isis"), the technology transfer company of the
#   University, to negotiate a licence. Contact details are:
#   innovation@isis.ox.ac.uk quoting reference DE/1112.

Usage() {
    echo ""
    echo "Usage: `basename $0` <4dinput> <4doutput> <reference_no> [<cost_function>]"
    echo "   where <cost_function> = {mutualinfo,corratio,normcorr,normmi,leastsq,labeldiff}"
    echo "                           (default is corratio)"
    echo ""
    exit 1
}

# --- Check input args ---
##[ "$3" = "" ] && Usage
if [ $# -lt 3 -o $# -gt 4 ]; then
    Usage
fi

input=`${FSLDIR}/bin/remove_ext ${1}`
output=`${FSLDIR}/bin/remove_ext ${2}`

ref=${3}
costfunction="corratio"
if [ $# -eq 4 ]; then
    costfunction=${4}
fi

if [ `${FSLDIR}/bin/imtest $input` -eq 0 ];then
    echo "Input does not exist or is not in a supported format"
    exit 1
fi

# --- set some filenames ---
xform_params=${output}_xformpars.txt
affine_absrms=${output}_affabs.rms
affine_relrms=${output}_affrel.rms
rigid_absrms=${output}_rigabs.rms
rigid_relrms=${output}_rigrel.rms

fslroi $input ${output}_ref $ref 1

fslsplit $input ${output}_tmp
full_list=`${FSLDIR}/bin/imglob ${output}_tmp????.*`

# create an identity matrix for RELRMS and ABSRMs calc below
ident_matrix=ident_mat_${RANDOM}.txt
cat << 'EOF' > $ident_matrix
1.000000 0.000000 0.000000 0.000000 
0.000000 1.000000 0.000000 0.000000 
0.000000 0.000000 1.000000 0.000000 
0.000000 0.000000 0.000000 1.000000
EOF

rm -f $affine_absrms $affine_relrms $rigid_absrms $rigid_relrms $xform_params
count=0
for i in $full_list ; do
    echo processing $i
    #echo processing $i >> ${output}.ecclog
    
    # This is the original "eddy-correct" call
    #${FSLDIR}/bin/flirt -in $i -ref ${output}_ref -nosearch -o $i -paddingsize 1 >> ${output}.ecclog 

    # modified: call Flirt w/ choice of cost function
    num=`printf "%4.4d" $count`
    affmat=${output}_affmat$num.txt
    ${FSLDIR}/bin/flirt -cost $costfunction -in $i -ref ${output}_ref -nosearch -o $i -omat $affmat -paddingsize 1 

    # extract rigid-body component of (possibly) Affine xform for motion estimate 
    rigmat=${output}_rigmat$num.txt
#    ~melliot/programs/matlab_binaries/affine_decompose.sh $matfile > $rigidfile
    avscale --allparams $affmat | grep -A 4 "Rotation & Translation Matrix:" | tail -n 4 > $rigmat

    # extract translations and rotations from motion xform
    trans=$(avscale --allparams $affmat | grep "Translations (x,y,z)"    | tr "=" "\n" | tail -n 1)
    rots=$(avscale --allparams $affmat | grep "Rotation Angles (x,y,z)" | tr "=" "\n" | tail -n 1)
    echo $trans " " $rots >> $xform_params

    # compute absolute RMS displacement from reference volume
    ${FSLDIR}/bin/rmsdiff $ident_matrix $affmat ${output}_ref >> $affine_absrms
    ${FSLDIR}/bin/rmsdiff $ident_matrix $rigmat ${output}_ref >> $rigid_absrms

    # compute relative RMS displacement from previous volume
    if [ $count -gt "0" ] ; then
        ${FSLDIR}/bin/rmsdiff $last_affmat $affmat ${output}_ref >> $affine_relrms
        ${FSLDIR}/bin/rmsdiff $last_rigmat $rigmat ${output}_ref >> $rigid_relrms  
    fi
    last_affmat=$affmat
    last_rigmat=$rigmat

    let count=$count+1
done

fslmerge -t $output $full_list

/bin/rm ${output}_tmp????.* ${output}_ref* $ident_matrix 
#/bin/rm ${output}_affmat*.txt ${output}_rigmat*.txt

exit 0

