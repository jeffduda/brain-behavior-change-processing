#!/bin/bash
# ---------------------------------------------------------------
# DICO_CORRECT.sh
#
# Use B0map from "dico_b0calc.sh" to correct distortions in EPIs
#
# Created: M Elliott 1/2010
# ---------------------------------------------------------------


# --- Set AFNI/FSL defaults ---
export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

# --- Set defaults ---
use_dcm2nii=0		# Use dcm2nii to make Niftis
de_oblique=0    	# Use 3dWarp to regrid oblique acqusition
do_moco=0			# moco EPI timeseries w/ mcflirt
keep_files=0		# keep intermediate files around (for debugging)
example_dicom=0		# use an example dicom and 4D Nifti rather than convert a folder of EPIs to Nifti
force_RPI=0         # force result to be RPI
do_smooth=0			# smooth3 option to FUGUE
unwarp_sign=0		# sign for fugue's "unwarpdir" (i.e. "+" or "-") 
opterr=0

#--- Parse command line switches ---
while getopts "s:dumkehFpn" Option
do
  case $Option in
	s ) do_smooth=$OPTARG;;
	d ) de_oblique=1;;
	u ) use_dcm2nii=1;;
	m ) do_moco=1;;
	k ) keep_files=1;;
    F ) force_RPI=1;;
	p ) unwarp_sign="+";;
	n ) unwarp_sign="-";;
	e ) example_dicom=1;;
	h ) opterr=1;;	# "-h" option used for help
	* ) opterr=1;;   # Error, illegal option.
  esac
done
shift $(($OPTIND - 1))

# --- Check remaining args ---
if [ $example_dicom -eq 0 -a $# -lt 2 ]; then
	opterr=1
fi
if [ $example_dicom -eq 1 -a $# -lt 3 ]; then
	opterr=1
fi

# --- Error in command line ---
if [ $opterr -eq 1 ]; then
cat << EOF
USAGE: 
`basename $0` -p/-n [-dumkehF] [-s sigma] EPI_dicom_directory b0map_directory [output_directory]
	or
`basename $0` -p/-n [-dumkehF] [-s sigma] -e example_dicomfile EPI_niftifile b0map_directory [output_directory]
	
OPTIONS:
    -p	apply FUGUE correction in "+" direction (e.g. X+ or Y+) (one of -p or -n is REQUIRED)
    -n	apply FUGUE correction in "-" direction (e.g. X- or Y-) 
    -d	de_OBLIQUE using AFNI "3dWarp" (default = OFF)
    -u	use "dcm2nii" for Nifti conversion (default = OFF, use AFNI "to3d" instead)
    -m	motion correct EPIs first with mcflirt (default = OFF)
    -k	keep intermediate files (default = OFF)
    -e	example dicom file for header info. Use this to correct 3D or 4D Nifti data file.
    -F  Force Nifti conversion to make RPI orientation
    -s	use "smooth3" option to fugue with sigma (mm)
    -h	print this Help info			
EOF
	exit 1
fi

if [ ${unwarp_sign} == "0" ]; then
	echo "ERROR: You MUST choose either -p or -n"
	exit 1
fi

# --- Work on raw dicoms in a folder ---
if [ $example_dicom -eq 0 ]; then  
  nifti_file=epi_raw.nii 		# this is what we will make from dicoms	
  DATA_DIR=$1
  B0MAP_DIR=$2
  DICOM_DIR=${DATA_DIR}  
  if [ $# -gt 2 ]; then
	WDIR=$3
  else
	WDIR=${DATA_DIR}
  fi

# --- Work on 4D Nifti, with example dicom file ---
else 
  dicom_file=`basename $1`
  nifti_file=`basename $2`
  DICOM_DIR=`dirname $1`
  DATA_DIR=`dirname $2`
  B0MAP_DIR=$3
  if [ $# -gt 3 ]; then
	WDIR=$4
  else	different_outputfolder=0	# save result in folder with data file
	WDIR=${DATA_DIR}
  fi
fi

# --- check for exsitence of files ---
if [ ! -d ${WDIR} ]; then
	echo "ERROR: output directory (${WDIR}) does not exist"
	exit 1
fi
if [ ! -d ${B0MAP_DIR} ]; then
	echo "ERROR: B0map directory (${B0MAP_DIR}) does not exist"
	exit 1
fi
if [ ! -d ${DATA_DIR} ]; then
	echo "ERROR: data directory (${DATA_DIR}) does not exist"
	exit 1
fi
if [ $example_dicom -eq 1 ]; then  
  if [ ! -e ${1} ]; then
	echo "ERROR: example dicom file (${1}) does not exist"
	exit 1
  fi
  if [ ! -e ${2} ]; then
	echo "ERROR: Nifti file (${2}) does not exist"
	exit 1
  fi
fi

# --- Convert all pathnames to absolute pathnames ---
EXECDIR=`dirname $0`
OCD=$PWD;	cd ${DATA_DIR};		DATA_DIR=$PWD
cd $OCD;	cd ${B0MAP_DIR};	B0MAP_DIR=$PWD
cd $OCD;	cd ${WDIR}; 		WDIR=$PWD
cd $OCD;	cd ${DICOM_DIR}; 	DICOM_DIR=$PWD
cd $OCD;
if [ "X${EXECDIR}" != "X" ]; then 
    cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD
fi

# --- Save results in different folder? ---
if [ "${DATA_DIR}" = "${WDIR}" ]; then
	different_outputfolder=0
else
	different_outputfolder=1	
fi

# --- Convert dicoms to Nifti ---
cd ${DATA_DIR}
if [ $example_dicom -eq 0 ]; then
	FILES=(`ls *.dcm`)
	NREPS=${#FILES[@]}
	if [ $NREPS = "0" ]; then
        echo "ERROR: No files matching *.dcm found in ${DATA_DIR}"
        exit 1
    fi
	dicom_file=${FILES[0]}
    options=""
    if [ $use_dcm2nii -eq 1 ]; then options=u${options}; fi
    if [ $de_oblique  -eq 1 ]; then options=d${options}; fi
    if [ $keep_files  -eq 1 ]; then options=k${options}; fi
    if [ $force_RPI   -eq 1 ]; then options=F${options}; fi
    if [ X$options != "X"   ]; then options=-${options}; fi
    ${EXECDIR}dicom2nifti.sh $options $nifti_file ${FILES[@]} ; if [ $? -eq 1 ]; then exit 1; fi
fi
nifti_original=$nifti_file # remember name of original Nifti file

# --- If results desired in separate folder, move/copy data file there ---
if [ $different_outputfolder -eq 1 ]; then
	if [ $example_dicom -eq 0 ]; then
		mv -f $nifti_file ${WDIR}
	else
		cp -f $nifti_file ${WDIR}
	fi
fi

# --- Make copy of B0map in results folder ---
cp -f ${B0MAP_DIR}/b0map.shims  ${WDIR}/b0map_copy.shims
cp -f ${B0MAP_DIR}/rpsmap.nii	${WDIR}/rpsmap_copy.nii
cp -f ${B0MAP_DIR}/mask.nii		${WDIR}/mask_copy.nii
cd ${WDIR}

# --- Check that voxel grids match and regrid if needed ---
EP_xform=`fslorient -getsform $nifti_file`      # get xform
B0_xform=`fslorient -getsform rpsmap_copy.nii`
EP_xform=`printf "%1.1f " $EP_xform`            # set precision for our comparison
B0_xform=`printf "%1.1f " $B0_xform`
EP_xform=${EP_xform//-0.0/0.0}                  # remove problematic "-0.0" string
B0_xform=${B0_xform//-0.0/0.0}
EP_xform="$EP_xform `fslval $nifti_file dim1` `fslval $nifti_file dim2` `fslval $nifti_file dim3`"      # append matrix size
B0_xform="$B0_xform `fslval rpsmap_copy.nii dim1` `fslval rpsmap_copy.nii dim2` `fslval rpsmap_copy.nii dim3`"
#echo $EP_xform
#echo $B0_xform
if [ "$EP_xform" != "$B0_xform" ] ; then
    echo "Grids and orientations of EPI and B0map do no match."
    ! (3dinfo $nifti_file     | grep "Data Axes Tilt" | grep "Oblique") &> /dev/null ; EP_oblique=$?
    ! (3dinfo rpsmap_copy.nii | grep "Data Axes Tilt" | grep "Oblique") &> /dev/null ; B0_oblique=$?

    # --- AFNI regrid for non-obliques ---
    if [ $EP_oblique -eq 0 -a $B0_oblique -eq 0 ] ; then
        echo "Both EPI and B0map are NOT oblique. Regridding B0map with AFNI 3Dresample."
	    rm -f rpsmap_regrid.nii mask_regrid.nii
	    3dresample -inset rpsmap_copy.nii -master $nifti_file -prefix rpsmap_regrid.nii # -rmode Li ??
	    3dresample -inset mask_copy.nii   -master $nifti_file -prefix mask_regrid.nii   # -rmode Li
	    B0MAP_FILE=rpsmap_regrid.nii
	    MASK_FILE=mask_regrid.nii

    # --- ITK regrid for obliques ---
    else
	    echo "At least one of EPI and B0map are oblique. Regridding B0map with ITK regridImage."
	    rm -f rpsmap_regrid.nii mask_regrid.nii epi_vol0.nii
	    NREPS=`fslval $nifti_file dim4`
	    if [ $NREPS -gt 1 ] ; then				# ITK regrid only works on 3D target, not 4D
		    nifti_vol0=epi_vol0.nii
		    3dbucket -prefix $nifti_vol0 ${nifti_file}\[0\] &> /dev/null # this DOES work for obliques
	    else
		    nifti_vol0=$nifti_file
	    fi
 	    ${EXECDIR}regridImage -d rpsmap_copy.nii -r $nifti_vol0 -p rpsmap_regrid 2>/dev/null
	    ${EXECDIR}regridImage -d mask_copy.nii   -r $nifti_vol0 -p mask_regrid 2>/dev/null
		B0MAP_FILE=rpsmap_regrid.nii
	    MASK_FILE=mask_regrid.nii
    fi
# -- no regrid ---
else
	echo "Grids and orientations of EPI and B0map match. No regridding needed."
    B0MAP_FILE=rpsmap_copy.nii
	MASK_FILE=mask_copy.nii	
fi

# --- get ACQ params ---
echo "Getting acq params from `basename ${DICOM_DIR}/${dicom_file}`"
dcminfo=(`dicom_hdr -sexinfo ${DICOM_DIR}/${dicom_file} 2>/dev/null | grep "sPat.lAccelFactPE"`)
np=${#dcminfo[@]}
GRAPPA=${dcminfo[$np-1]}
dcminfo=(`dicom_hdr -sexinfo ${DICOM_DIR}/${dicom_file} 2>/dev/null | grep "lEchoSpacing"`)
if [ $? -eq 0 ] ; then	# ESP only stored in header for user-chosen ESP
	np=${#dcminfo[@]}
	ESP=${dcminfo[$np-1]}
	ESP=`echo "scale=6; $ESP /1000000" | bc`	# use 'bc' to do math - convert usec to sec
else
	dcminfo=(`dicom_hdr -sexinfo ${DICOM_DIR}/${dicom_file} 2>/dev/null | grep "Pixel Bandwidth"`)
	np=${#dcminfo[@]}
	PBW=`echo ${dcminfo[$np-1]} | tr -d 'Bandwidth//'`
	echo PBW = $PBW
	ESP=`echo "scale=6; 1/$PBW + 0.000082" | bc`	# use 'bc' to do math - convert pixbw to esp in sec
fi									
ESP_COR=`echo "scale=6; $ESP/$GRAPPA" | bc`
dcminfo=(`dicom_hdr ${DICOM_DIR}/${dicom_file} 2>/dev/null | grep -i "0018 1312"`)
np=${#dcminfo[@]}
PEDIR=`echo ${dcminfo[$np-1]} | tr -d 'Direction//'`
! (dicom_hdr -sexinfo ${DICOM_DIR}/${dicom_file} | grep -q "dInPlaneRot") 2> /dev/null
PEREVERSED=$?   # phase encoding direction is rotated (i.e. A->P becomes P->A) 
if [ $PEDIR = "ROW" ]; then
	UNWARP_DIR="x"
elif [ $PEDIR = "COL" ]; then
	UNWARP_DIR="y"	
else
	echo "ERROR: Strange PEDIR value: $PEDIR"
	exit 1
fi
if [ ${unwarp_sign} == "-" ]; then
	UNWARP_DIR=${UNWARP_DIR}${unwarp_sign}
fi	

# --- Get size of EPI image in direction that is distorted ---
if [ $PEDIR = "ROW" ]; then
	dimkey="dim1"
else
	dimkey="dim2"
fi
diminfo=`fslinfo $nifti_file | grep -w $dimkey`
NP=(`echo $diminfo | cut -c 6-`)
echo NP = $NP, GRAPPA = $GRAPPA, PEDIR = $PEDIR, PEREVERSED = $PEREVERSED, ESP = $ESP, Grappa corrected ESP = $ESP_COR
echo "FSL FUGUE direction = $UNWARP_DIR"

# --- Get shim current values used for this acq ---
rm -f epi.shims
${EXECDIR}dicom_get_shim.sh ${DICOM_DIR}/${dicom_file} > epi.shims

# --- check that shims from B0map acq match EPI acq ---
b0shims=( `cat b0map_copy.shims` )
epshims=( `cat epi.shims` )
b0shims="${b0shims[0]} ${b0shims[1]} ${b0shims[2]}" # just compare X/Y/Z vals, cuz other vals are unreliable
epshims="${epshims[0]} ${epshims[1]} ${epshims[2]}"
if [ "$epshims" != "$b0shims" ]; then
	echo "WARNING: EPI images were not acquired with the same shim settings as the B0map."
	echo "  B0map shim currents:"
	cat b0map_copy.shims
	echo "  EPI shim currents:"
	cat epi.shims
#	exit 1	
fi

# --- Motion correct EPIs ---
if [ $do_moco = "1" ]; then
	echo ""
	echo "-----------------------------------------------"
	echo "Motion correcting EPIs..."
	rm -fr epi_mc.mat
	mcflirt -rmsrel -rmsabs -in $nifti_file -refvol 0 -out epi_mc
	nifti_file=epi_mc.nii
fi

# --- Distortion correct EPIs with FSL---
rm -f epi_dico.nii
#cmd="fugue -i $EPIFILE --loadfmap=radmap --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --poly=4 --unmaskshift --saveshift=shiftmap -u epi_dico" 
#cmd="fugue -i $EPIFILE --loadfmap=radmap --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --fourier=4 --unmaskshift --saveshift=shiftmap -u epi_dico" 
#cmd="fugue -i $EPIFILE --loadfmap=radmap --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --fourier=2 --unmaskshift --saveshift=shiftmap -u epi_dico" 
#cmd="fugue -i $EPIFILE --loadfmap=radmap --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --smooth3=2 --unmaskshift --saveshift=shiftmap -u epi_dico" 
#cmd="fugue -i $nifti_file --loadfmap=$B0MAP_FILE --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --smooth3=$do_smooth --noextend --unmaskshift --saveshift=shiftmap -u epi_dico" 
cmd="fugue -i $nifti_file --loadfmap=$B0MAP_FILE --mask=$MASK_FILE --unwarpdir=$UNWARP_DIR --dwell=$ESP_COR --smooth3=$do_smooth --unmaskshift --saveshift=shiftmap -u epi_dico" 
echo "-----------------------------------------------"
echo "Running fugue command:"
echo $cmd
eval $cmd
echo ""

# --- Make our own calculation of the shiftmap (should match FSL's) ---
#rm -f shiftmap2.nii
#fslmaths $B0MAP_FILE -mul $ESP_COR -mul $NP  shiftmap2 -odt float

# --- remove intermediate files ---
if [ $keep_files -eq 0 ]; then
	rm -f rpsmap_copy.nii mask_copy.nii radmap.nii $B0MAP_FILE $MASK_FILE rpsmap_copy.shims $nifti_vol0
	rm -f epi_mc.nii epi.shims
	rm -fr epi_mc.mat
#	if [ $different_outputfolder -eq 1 ]; then
#		rm -f $nifti_original
#	fi
fi

cd $OCD
echo "Done."
exit 0
