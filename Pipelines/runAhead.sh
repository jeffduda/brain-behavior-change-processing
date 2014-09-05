#!/bin/bash

usage()
{
cat << EOF
usage: $0 options

This script run the test1 or test2 over a machine.

OPTIONS:
   -h      Show this message
   -i      input image - typically an mprage image
   -t      template directory
   -o      output directory
   -v      Verbose
EOF
}

IMG=
VERBOSE=
ODIR=
TEMPLATEDIR=
EXE=
ONAME=

while getopts “hi:e:t:d:o:v” OPTION
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
             TEMPLATEDIR=$OPTARG
             ;;
         d)
             ODIR=$OPTARG
             ;;
         o) 
             ONAME=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
         e) 
             EXE=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ ! -d $ODIR ]; then
  mkdir -p $ODIR
fi

cp $IMG ${ODIR}/
FNAME=$(basename $IMG)
INPUT="${ODIR}/${FNAME}"

if [[ $file =~ \.gz$ ]]; then
 :
else
  gzip -f $INPUT
  INPUT="${INPUT}.gz"
fi
FNAME=$(basename $INPUT .nii.gz)

if [[ -z $IMG ]]
then
  usage
  exit 1
fi

cmd="$EXE $ODIR $ODIR $FNAME $TEMPLATEDIR 1"

echo "Running AHEAD"
echo $cmd
$cmd
echo "DONE"

# cleanup
cp ${ODIR}/${FNAME}/${FNAME}_wholebrainseg.nii.gz $ONAME
rm -R ${ODIR}/${FNAME}
  
  
  
  
