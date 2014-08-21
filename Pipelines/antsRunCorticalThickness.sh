#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

This script run the test1 or test2 over a machine.

OPTIONS:
   -h      Show this message
   -i      input image - typically an mprage images
   -t      template name: [ "Kirby" ] - more options to come
   -o      output directory
   -v      Verbose
EOF
}

IMG=
VERBOSE=
ODIR=
TEMPLATENAME="Kirby"

while getopts “hi:t:o:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         i)
             IMG=$OPTARG
             ;;
         t) 
             TEMPLATENAME=$OPTARG
             ;;
         o)
             ODIR=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $IMG ]]
then
  usage
  exit 1
fi

TEMPLATE=
MASK=
EMASK=
PRIORS=

if [[ "$TEMPLATENAME" == "Kirby" ]]; then
  TDIR="/data/jet/jtduda/data/Templates/Kirby/"
  TEMPLATE="${TDIR}S_template3.nii.gz"
  MASK="${TDIR}S_template_BrainCerebellumProbabilityMask.nii.gz"
  EMASK="${TDIR}S_template_BrainCerebellumExtractionMask.nii.gz"
  PRIORS="${TDIR}Priors/priors%d.nii.gz"
  BRAIN="${TDIR}S_template3_BrainCerebellum.nii.gz"
  
fi

BASENAME=`basename $IMG .nii` 
export ANTSPATH=/data/jet/jtduda/bin/ants/

ANTS_PIPELINE=/data/jet/jtduda/bin/ants/antsCorticalThickness.sh

cmd="bash ${ANTS_PIPELINE} -d 3 \
  -a $IMG \
  -e ${TEMPLATE} \
  -m ${MASK} \
  -f ${EMASK} \
  -p ${PRIORS} \
  -t ${BRAIN} \
  -k 0 \
  -n 3 \
  -w 0.25 \
  -o ${ODIR}"
  
$cmd
  
  
  
  
  
