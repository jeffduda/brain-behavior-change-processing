#!/bin/bash

VERSION="0.0"

function Usage {
    cat <<USAGE

`basename $0` performs DTI reconstruction and alignment to T1 image:

Usage:

`basename $0` -i input bold image
              -o output bold image
              -s structural image from same session
              -x structural image brain mask
              -t prefix for t1 to template transform
Example:
  $0 -i /input/mytaskbold.nii -o /results/mytaskbold.nii.gz -s /input/myt1.nii -x /input/myt1mask.nii
Required arguments:

    

USAGE
    exit 1
}


echoParameters() {
    cat <<PARAMETERS

    Using runBOLDPrep with the following arguments:
      input file              = ${BOLD}
      output file             = ${OUTPUT}
      structural image        = ${T1}
      structural brain mask   = ${MASK}
      t1 template transform   = ${TEMPLATE_TRANSFORM}   

PARAMETERS
}


# Echos a command to both stdout and stderr, then runs it
function logCmd() {
  cmd="$*"
  echo "BEGIN >>>>>>>>>>>>>>>>>>>>"
  echo $cmd
  $cmd
  echo "END   <<<<<<<<<<<<<<<<<<<<"
  echo
  echo
}

BOLD=""
T1=""
MASK=""
OUTPUT=""
TEMPLATE_TRANSFORM=""

################################################################################
#
# Programs and their parameters
#
################################################################################

if [[ $# -lt 3 ]] ; then
  Usage >&2
  exit 1
else
  while getopts "d:i:m:o:p:w:s:t:x:" OPT
    do
      case $OPT in
          i) #rain extraction registration mask
              BOLD=$OPTARG
              ;;
          o) #brain extraction anatomical image
              OUTPUT=$OPTARG
              ;;
          s) # protocol file
              T1=$OPTARG
              ;;
          x) #brain extraction registration mask
              MASK=$OPTARG
              ;;
          t) # t1 tempalte transform prefix
             TEMPLATE_TRANSFORM=$OPTARG
             ;;
          *) # getopts issues an error message
              echo "ERROR:  unrecognized option -$OPT $OPTARG"
              exit 1
              ;;
      esac
  done
fi
shift $(( OPTIND - 1 ))

# echo input options
echoParameters

  
# Copy dicom tar files into a tmp working dir on node
TEMPDIR=`mktemp -d`
#TEMPDIR=/data/jet/jtduda/data/Temp/BOLD
echo "Temp working space is $TEMPDIR"

if [ ! -d "$TEMPDIR" ]; then
  echo "FAILED TO CREATE TEMP WORKING SPACE"
  exit 1
fi

OUTNAME="${OUTPUT%%.*}"
OUTNAME=`basename $OUTNAME`;
OUTBOLD=`basename $OUTPUT`;

BOLDFILE=`basename $BOLD`;
BOLDNAME="${BOLDFILE%%.*}"

OUTDIR=`dirname $OUTPUT`;

if [ ! -d "$OUTDIR" ]; then
  mkdir -p $OUTDIR
fi
if [ ! -d "$OUTDIR" ]; then
  echo "FAILED TO CREATE OUTPUT DIRECTORY"
  exit 1
fi
  

#if [ ! -s "$OUTPUT" ]; then
if [ ! -s "${OUTDIR}/${OUTNAME}_MOCOparams.csv" ]; then

  echo "Motion Correction"

  # copy files to local tmp dir on node.
  # extracting over mounted filesystem
  # can be problematic when running many
  # jobs at once

  cp $BOLD $TEMPDIR/$OUTBOLD
  ${ANTSPATH}ImageMath 4 $TEMPDIR/$OUTBOLD SliceTimingCorrection $TEMPDIR/$OUTBOLD 0 sinc
  ${ANTSPATH}antsMotionCorr -d 3 -a $TEMPDIR/$OUTBOLD -o $TEMPDIR/${OUTNAME}_mean.nii.gz
  ${ANTSPATH}antsMotionCorr -d 3 -o [ ${TEMPDIR}/${OUTNAME}_, ${TEMPDIR}/$OUTBOLD, ${TEMPDIR}/${OUTNAME}_mean.nii.gz ] -u 1 -m mi[ ${TEMPDIR}/${OUTNAME}_mean.nii.gz, ${TEMPDIR}/$OUTBOLD, 1, 32, Regular, 0.05 ] -t Affine[0.2] -i 25 -e 1 -f 1 -s 0 -l 0

  cp ${TEMPDIR}/${OUTBOLD} ${OUTPUT}
  cp ${TEMPDIR}/${OUTNAME}_mean.nii.gz ${OUTDIR}/
  cp ${TEMPDIR}/${OUTNAME}_MOCOparams.csv ${OUTDIR}/

fi # End BOLD preprocessing



if [ ! -s "${OUTDIR}/${OUTNAME}_1Warp.nii.gz" ]; then
      
    echo "Intra sub alignment"
    
    echo "OUTPUT NAME: $OUTNAME"
    ${ANTSPATH}ImageMath 3 ${TEMPDIR}/${OUTNAME}_anat.nii.gz m $T1 $MASK         
    ${ANTSPATH}ResampleImageBySpacing 3 ${TEMPDIR}/${OUTNAME}_anat.nii.gz ${TEMPDIR}/${OUTNAME}_anat.nii.gz 2 2 2
    reg="sh ${ANTSPATH}antsIntermodalityIntrasubject.sh -d 3 -t 3 -i ${OUTDIR}/${OUTNAME}_mean.nii.gz -r ${TEMPDIR}/${OUTNAME}_anat.nii.gz -x $MASK -o ${TEMPDIR}/${OUTNAME}_ -w $TEMPLATE_TRANSFORM "
    $reg
    
    ${ANTSPATH}antsApplyTransforms -d 3 -i $MASK -o ${TEMPDIR}/${OUTNAME}_Mask.nii.gz -t [ ${TEMPDIR}/${OUTNAME}_0GenericAffine.mat, 1] -t ${TEMPDIR}/${OUTNAME}_1InverseWarp.nii.gz -r ${OUTDIR}/${OUTNAME}_mean.nii.gz
    ${ANTSPATH}/ThresholdImage 3 ${TEMPDIR}/${OUTNAME}_Mask.nii.gz ${TEMPDIR}/${OUTNAME}_Mask.nii.gz 0.5 inf
      
    cp ${TEMPDIR}/${OUTNAME}_Mask.nii.gz ${OUTDIR}/
    cp ${TEMPDIR}/${OUTNAME}_0GenericAffine.mat ${OUTDIR}/
    cp ${TEMPDIR}/${OUTNAME}_1Warp.nii.gz ${OUTDIR}/
    cp ${TEMPDIR}/${OUTNAME}_1InverseWarp.nii.gz ${OUTDIR}/
    
    
fi

rm -R ${TEMPDIR}

echo "Done."


