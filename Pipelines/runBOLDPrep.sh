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
              -w prefix for t1 to template transform
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
TEMPLATE=""

################################################################################
#
# Programs and their parameters
#
################################################################################

if [[ $# -lt 3 ]] ; then
  Usage >&2
  exit 1
else
  while getopts "d:i:m:o:p:w:s:t:w:x:" OPT
    do
      case $OPT in
          i) # original bold image
              BOLD=$OPTARG
              ;;
          o) # output bold image
              OUTPUT=$OPTARG
              ;;
          s) # anatomical image
              T1=$OPTARG
              ;;
          x) # anatomical image brain mask
              MASK=$OPTARG
              ;;
          w) # name of anatomical -> template transfomr
             TEMPLATE_TRANSFORM=$OPTARG
             ;;
          t) # template
             TEMPLATE=$OPTARG
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

  #echo "Motion Correction"
#--------------------------------------------------------------------------------------
# Cortical thickness using DiReCT (KellyKapowski)
#--------------------------------------------------------------------------------------

  # copy files to local tmp dir on node.
  # extracting over mounted filesystem
  # can be problematic when running many
  # jobs at once

  logCmd cp $BOLD $TEMPDIR/$OUTBOLD

  logCmd ${ANTSPATH}antsMotionCorr -d 3 -a $TEMPDIR/$OUTBOLD -o $TEMPDIR/${OUTNAME}_mean.nii.gz
  logCmd ${ANTSPATH}antsMotionCorr -d 3 -o [ ${TEMPDIR}/${OUTNAME}_, ${TEMPDIR}/$OUTBOLD, ${TEMPDIR}/${OUTNAME}_mean.nii.gz ] -u 1 -m mi[ ${TEMPDIR}/${OUTNAME}_mean.nii.gz, ${TEMPDIR}/$OUTBOLD, 1, 32, Regular, 0.05 ] -t Rigid[0.2] -i 25 -e 1 -f 1 -s 0 -l 0

  logCmd cp ${TEMPDIR}/${OUTBOLD} ${OUTPUT}
  logCmd cp ${TEMPDIR}/${OUTNAME}_mean.nii.gz ${OUTDIR}/
  logCmd cp ${TEMPDIR}/${OUTNAME}_MOCOparams.csv ${OUTDIR}/


fi # End BOLD preprocessing

if [ ! -s "${OUTDIR}/${OUTNAME}_1Warp.nii.gz" ]; then

    #echo "Intra sub alignment"
#--------------------------------------------------------------------------------------
# Cortical thickness using DiReCT (KellyKapowski)
#--------------------------------------------------------------------------------------

    logCmd ${ANTSPATH}antsBrainExtraction.sh -d 3 -a ${OUTDIR}/${OUTNAME}_mean.nii.gz -e $T1 -m $MASK -q 1 -o ${TEMPDIR}/${OUTNAME}_

    #echo "OUTPUT NAME: $OUTNAME"
    logCmd ${ANTSPATH}ImageMath 3 ${TEMPDIR}/${OUTNAME}_anat.nii.gz m $T1 $MASK
    logCmd ${ANTSPATH}ResampleImageBySpacing 3 ${TEMPDIR}/${OUTNAME}_anat.nii.gz ${TEMPDIR}/${OUTNAME}_anat.nii.gz 2 2 2
    reg="sh ${ANTSPATH}antsIntermodalityIntrasubject.sh -d 3 -t 3 -i ${TEMPDIR}/${OUTNAME}_BrainExtractionBrain.nii.gz -r ${TEMPDIR}/${OUTNAME}_anat.nii.gz -x $MASK -o ${TEMPDIR}/${OUTNAME}_ -w $TEMPLATE_TRANSFORM -T ${TEMPLATE_TRANSFORM}1Warp.nii.gz"
    logCmd $reg

    logCmd ${ANTSPATH}antsApplyTransforms -d 3 -i $MASK -o ${TEMPDIR}/${OUTNAME}_Mask.nii.gz -t [ ${TEMPDIR}/${OUTNAME}_0GenericAffine.mat, 1] -t ${TEMPDIR}/${OUTNAME}_1InverseWarp.nii.gz -r ${OUTDIR}/${OUTNAME}_mean.nii.gz
    logCmd ${ANTSPATH}/ThresholdImage 3 ${TEMPDIR}/${OUTNAME}_Mask.nii.gz ${TEMPDIR}/${OUTNAME}_Mask.nii.gz 0.5 inf
    logCmd ${ANTSPATH}/ImageMath 3 ${TEMPDIR}/${OUTNAME}_Brain.nii.gz m ${TEMPDIR}/${OUTNAME}_Mask.nii.gz ${OUTDIR}/${OUTNAME}_mean.nii.gz

    logCmd cp ${TEMPDIR}/${OUTNAME}_Mask.nii.gz ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_0GenericAffine.mat ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_Brain.nii.gz ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_1Warp.nii.gz ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_1InverseWarp.nii.gz ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_anatomical.nii.gz ${OUTDIR}/
    logCmd cp ${TEMPDIR}/${OUTNAME}_template.nii.gz ${OUTDIR}/

    logCmd rm ${TEMPDIR}/${OUTNAME}*

fi

if [ ! -s "${OUTDIR}/${OUTNAME}_MOCOstats.csv" ]; then
  logCmd ${ANTSPATH}/antsMotionCorrStats -m ${OUTDIR}/${OUTNAME}_MOCOparams.csv -x ${OUTDIR}/${OUTNAME}_Mask.nii.gz -o ${OUTDIR}/${OUTNAME}_MOCOstats.csv --framewise
fi

if [ ! -s "${OUTDIR}/${OUTNAME}_compcorr_compcorr.csv" ]; then
  logCmd ${ANTSPATH}/ImageMath 4 ${OUTDIR}/${OUTNAME}_compcorr.nii.gz CompCorrAuto $BOLD ${OUTDIR}/${OUTNAME}_Mask.nii.gz 6
fi

if [ ! -s "${OUTDIR}/${OUTNAME}_QA.png" ]; then
  logCmd /data/jag/bbcp/pkg/R/build/bin/Rscript /data/jag/bbcp/pkg/bbcp/Pipelines/boldSummary.R $BOLD ${OUTDIR}/${OUTBOLD} ${OUTDIR}/${OUTNAME}_Mask.nii.gz ${OUTDIR}/${OUTNAME}_MOCOparams.csv ${OUTDIR}/${OUTNAME}_compcorr_compcorr.csv ${OUTDIR}/${OUTNAME}_MOCOstats.csv ${OUTNAME} ${OUTDIR}/${OUTNAME}_QA.png
fi


### TEMP SECTION ###

if [ ! -s "${OUTDIR}/${OUTNAME}_mni.nii.gz" ]; then
  echo "NO MNI space image"
  #logCmd ${ANTPATH}/antsApplyTransforms -d 3 -e 3 --float -i $OUTPUT -o ${OUTDIR}/${OUTNAME}_mni.nii.gz -r /data/jet/jtduda/data/Templates/Kirby/MNI/MNI152_T1_2mm_BrainCerebellumMask.nii.gz -t /data/jet/jtduda/data/Templates/Kirby/MNI/Kirby2MNI_1Warp.nii.gz -t /data/jet/jtduda/data/Templates/Kirby/MNI/Kirby2MNI_0GenericAffine.mat -t $t1warp -t $t1aff -t $boldwarp -t $boldaff
fi

if [ ! -s "${OUTDIR}/${OUTNAME}_smooth.nii.gz" ]; then
  logCmd /data/jag/bbcp/pkg/R/build/bin/Rscript /data/jag/bbcp/pkg/bbcp/Pipelines/boldConnectivity.R ${OUTDIR}/${OUTNAME}_mni.nii.gz /data/jet/jtduda/data/Templates/Kirby/MNI/MNI152_T1_2mm_BrainCerebellumMask.nii.gz /data/jet/jtduda/data/Templates/Kirby/MNI/MNI152_T1_2mm_BrainSegmentation.nii.gz /data/jag/bbcp/Studies/BCP_pilot1/GroupResults/RestingState/zfstat1_cope10_2.33z_0.05p_mask_3.nii.gz ${OUTDIR}/${OUTNAME}_MOCOparams.csv ${OUTDIR}/${OUTNAME}_compcorr_compcorr.csv ${OUTDIR}/${OUTNAME}_smooth.nii.gz
  logCmd ${ANTSPATH}/ImageMath 4 ${OUTDIR}/${OUTNAME}_smooth.nii.gz G ${OUTDIR}/${OUTNAME}_smooth.nii.gz 5x5x5x0
fi

if [ ! -s "${OUTDIR}/${OUTNAME}_seedmap_1.nii.gz" ]; then
  logCmd /data/jag/bbcp/pkg/R/build/bin/Rscript /data/jag/bbcp/pkg/bbcp/Pipelines/seedConnectivity.R ${OUTDIR}/${OUTNAME}_smooth.nii.gz /data/jet/jtduda/data/Templates/Kirby/MNI/MNI152_T1_2mm_BrainCerebellumMask.nii.gz /data/jag/bbcp/Studies/BCP_pilot1/GroupResults/RestingState/seeds.nii.gz ${OUTDIR}/${OUTNAME}_seedmap
fi

### END TEMP SECTION ###

rm -R ${TEMPDIR}

echo "Done."
