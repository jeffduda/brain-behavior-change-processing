#!/bin/bash
# ---------------------------------------------------------------
# DICO_B0CALC.sh
#
# Calculate B0 map from double echo Siemens fieldmap sequence
# Uses FSL and AFNI to convert Dicom images to NIFTI format
# Images are phase unwrapped and in units of Hertz
#
# Created: M Elliott 1/2010
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Remove mean from image (lifted from FSL5 fsl_prepare_fieldmap)
demean_image() {
  # demeans image
  # args are: <image> <mask>
  infile=$1
  maskim=$2
  outfile=$3
  tmpnm=`$FSLDIR/bin/tmpnam`
  $FSLDIR/bin/fslmaths ${infile} -mas ${maskim} ${tmpnm}_tmp_fmapmasked
  $FSLDIR/bin/fslmaths ${infile} -sub `$FSLDIR/bin/fslstats ${tmpnm}_tmp_fmapmasked -k ${maskim} -P 50` -mas ${maskim} ${outfile} -odt float
  rm -rf ${tmpnm}_tmp_*
}
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Despike edges (lifted from FSL5 fsl_prepare_fieldmap)
clean_up_edge() {
    # does some despiking filtering to clean up the edge of the fieldmap
    # args are: <fmap> <mask> <tmpnam>
    infile=$1
    maskim=$2
    outfile=$3
    tmpnm=`$FSLDIR/bin/tmpnam`
    $FSLDIR/bin/fugue --loadfmap=${infile} --savefmap=${tmpnm}_tmp_fmapfilt --mask=${maskim} --despike --despikethreshold=2.1
    $FSLDIR/bin/fslmaths ${maskim} -kernel 2D -ero ${tmpnm}_tmp_eromask 
    $FSLDIR/bin/fslmaths ${maskim} -sub ${tmpnm}_tmp_eromask -thr 0.5 -bin ${tmpnm}_tmp_edgemask 
    $FSLDIR/bin/fslmaths ${tmpnm}_tmp_fmapfilt -mas ${tmpnm}_tmp_edgemask ${tmpnm}_tmp_fmapfiltedge
    $FSLDIR/bin/fslmaths ${infile} -mas ${tmpnm}_tmp_eromask -add ${tmpnm}_tmp_fmapfiltedge ${outfile}
    rm -rf ${tmpnm}_tmp_*
}
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# SET UP
# ---------------------------------------------------------------

# --- Set AFNI/FSL stuff ---
export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

# --- set defaults ---
de_oblique=0        # NOTE: This can be used if b0map or epi is obliqued
use_dcm2nii=0	    # Use dcm2nii to make Niftis
do_skullstrip=0	    # Skull-strip magnitude B0map image
keep_files=0        # keep intermediate files around (for debugging)
do_demean=0         # de-mean the rpsmap
do_despike=0        # de-spike the rpsmap
force_RPI=0         # force result to be RPI
bet_f="0.3"         # BET command f-factor
bet_g="0.0"         # BET comand g-factor
t1whole=""          # whole brain T1 structural
t1brain=""          # brain extracted T1 structural
brainmask=""        # mask for brain in fmap space
opterr=0

#--- Parse command line switches ---
while getopts "T:B:b:f:g:sdumkhFx" Option
do
  case $Option in
	T ) t1whole=$OPTARG;;
	B ) t1brain=$OPTARG;;
	b ) brainmask=$OPTARG;;
	f ) bet_f=$OPTARG;;
	g ) bet_g=$OPTARG;;
	s ) do_skullstrip=1;;
	m ) do_demean=1;;
	x ) do_despike=1;;
	d ) de_oblique=1;;
	k ) keep_files=1;;
	F ) force_RPI=1;;
	u ) use_dcm2nii=1;;
	h ) opterr=1;;	# "-h" option used for help
	* ) opterr=1;;   # Error, bad option.
  esac
done
shift $(($OPTIND - 1))

# --- Parse remaining command line ---
if [ $# -lt 2 -o $opterr -eq 1 ]; then
cat << EOF
USAGE: `basename $0` [-dukxmFh] magnitude_dicom_folder phase_dicom_folder [output_folder]
   
   or  `basename $0` [-dukxmFh] -s [-f BET_f] [-g BET_g] magnitude_dicom_folder phase_dicom_folder [output_folder]
            
   or  `basename $0` [-dukxmFh] -T T1head.nii -B T1brain.nii magnitude_dicom_folder phase_dicom_folder [output_folder]

   or  `basename $0` [-dukxmFh] -b brainmask.nii magnitude_dicom_folder phase_dicom_folder [output_folder]

OPTIONS:
    -T  Whole head T1 NIFTI file to be coregistered to fieldmap magnitude image (requires -B option).
    -B  Brain-masked T1 NIFTI file
    -b  Brain mask for fieldmap (in fieldmap space already)
    -s  Skullstrip (using BET) magnitude images (default = OFF)
    -f  Set BET command "f" value (default = ${bet_f})
    -g  Set BET command "g" value (default = ${bet_g})
    -d  De_oblique using AFNI "3dWarp" (default = OFF)
    -u  Use "dcm2nii" for Nifti conversion (default = OFF, use AFNI "to3d" instead)
    -m  Remove mean value from resulting fieldmap (i.e. rpsmap.nii) (default = OFF)
    -x  Remove spikes from the edges of the fieldmap (i.e. rpsmap.nii) (default = OFF)
    -F  Force Nifti results to be RPI orientation
    -k  keep intermediate files (default = OFF)
    -h  Print this Help info			
EOF
	exit 1
fi

# ---Handle remaining arguments ---
OCD=$PWD
EXECDIR=`dirname $0`
if [ "X${EXECDIR}" != "X" ]; then
    cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD # makes path absolute, leaves blank if none (i.e. this script is in the PATH)
fi
if [ $# -gt 2 ]; then
	WDIR=$3
else
	WDIR=$PWD
fi
if [ ! -d $WDIR ]; then
	echo "ERROR: output_directory ($WDIR) does not exist"
	exit 1
fi

# --- Check for conflicts of switches ---
if [ $do_skullstrip = "1" -a -n "$t1whole" ]; then
    echo "ERROR: You should not choose BOTH -s and -T"
    exit 1
fi
if [ $do_skullstrip = "1" -a -n "$brainmask" ]; then
    echo "ERROR: You should not choose BOTH -s and -b"
    exit 1
fi
if [ -n "$t1whole" -a -n "$brainmask" ]; then
    echo "ERROR: You should not choose BOTH -T and -b"
    exit 1
fi
if [ -n "$t1whole" -a -z "$t1brain" ]; then
    echo "ERROR: If you provide a T1head you MUST also provide a skull-stripped T1brain"
    exit 1
fi
if [ -n "$t1brain" -a -z "$t1whole" ]; then
    echo "ERROR: If you provide a skull-stripped T1brain you MUST also provide a T1head"
    exit 1
fi

# ---------------------------------------------------------------
# CONVERT MAGNITUDE FIELDMAP DICOMS TO NIFTI
# ---------------------------------------------------------------

# --- move to dicom folder ---
cd $OCD
cd $1

# --- get list of all dicoms ---
FILES=(`ls *.dcm`)
NFILES=${#FILES[@]}
if [ $NFILES = "0" ]; then
    echo "ERROR: No files matching *.dcm found in $1"
    exit 1
fi
let "N = $NFILES/2"

# --- make list of first half of the files (i.e. from TE1 acq) ---
LIST1=""
i="0"
while [ $i -lt $N ]; do
	LIST1="${LIST1} ${FILES[$i]}"
	i=$[$i+1]
done

# --- make list of 2nd half of the files (i.e. from TE2 acq) ---
LIST2=""
i=$N
while [ $i -lt $NFILES ] 
do
	LIST2="${LIST2} ${FILES[$i]}"
	i=$[$i+1]
done
MAG_NZ=$N

# --- convert Dicoms for fieldmap magnitude ---
options=""
if [ $use_dcm2nii -eq 1 ]; then options=u${options}; fi
if [ $de_oblique  -eq 1 ]; then options=d${options}; fi
if [ $keep_files  -eq 1 ]; then options=k${options}; fi
if [ $force_RPI   -eq 1 ]; then options=F${options}; fi
if [ X$options != "X"   ]; then options=-${options}; fi
${EXECDIR}dicom2nifti.sh $options fmap_mag1.nii $LIST1 ; if [ $? -eq 1 ]; then exit 1; fi
${EXECDIR}dicom2nifti.sh $options fmap_mag2.nii $LIST2 ; if [ $? -eq 1 ]; then exit 1; fi

# ---------------------------------------------------------------
# CONVERT PHASE FIELDMAP DICOMS TO NIFTI
# ---------------------------------------------------------------

# --- move to dicom folder ---
cd $OCD
cd $2

# --- get list of all dicoms ---
FILES=(`ls *.dcm`)
NFILES=${#FILES[@]}
if [ $NFILES = "0" ]; then
    echo "ERROR: No files matching *.dcm found in $2"
    exit 1
fi
let "N = $NFILES/2"

# --- Check that we match number of files from magnitude images ---
if [ $N -ne $MAG_NZ ]; then
	echo "ERROR: Magnitude and phase dicoms do match in number"
	exit 1
fi

# --- make list of first half of the files (i.e. from TE1 acq) ---
LIST1=""
i="0"
while [ $i -lt $N ] 
do
	LIST1="${LIST1} ${FILES[$i]}"
	i=$[$i+1]
done

# --- make list of 2nd half of the files (i.e. from TE2 acq) ---
LIST2=""
i=$N
while [ $i -lt $NFILES ] 
do
	LIST2="${LIST2} ${FILES[$i]}"
	i=$[$i+1]
done

# --- convert Dicoms for fieldmap phase from TE1 ---
${EXECDIR}dicom2nifti.sh $options fmap_phase1.nii $LIST1 ; if [ $? -eq 1 ]; then exit 1; fi
${EXECDIR}dicom2nifti.sh $options fmap_phase2.nii $LIST2 ; if [ $? -eq 1 ]; then exit 1; fi

# --- get TEs of each image ---
dcminfo=(`dicom_hdr ${FILES[0]} 2>/dev/null | grep -i "echo time"`) 
np=${#dcminfo[@]}
TE1=`echo ${dcminfo[$np-1]} | tr -d 'Time//'`
dcminfo=(`dicom_hdr ${FILES[$N]} 2>/dev/null | grep -i "echo time"`) 
np=${#dcminfo[@]}
TE2=`echo ${dcminfo[$np-1]} | tr -d 'Time//'`
dTE=`echo "scale=4; $TE2 - $TE1" | bc`	# do floating point math using "bc" command
echo "TE1 = $TE1, TE2 = $TE2, dTE = $dTE (msec)"

# --- Get shim current values used for this acq ---
rm -f b0map.shims
${EXECDIR}dicom_get_shim.sh ${FILES[0]} > b0map.shims

# --- find out if this is bipolar or monopolar multi-echo GRE ---
dcminfo=(`dicom_hdr -sexinfo ${FILES[0]} 2>/dev/null | grep -i "readoutmode"`) 2> /dev/null
np=${#dcminfo[@]}
ReadOutMode=${dcminfo[$np-1]}
if [ $ReadOutMode = "0x1" ]; then
    readout="monopolar"
	echo "monopolar read-out: OK"
elif [ $ReadOutMode = "0x2" ]; then
    readout="bipolar"
#	echo "bipolar read-out: OK"
	echo "ERROR: bipolar read-out: don't know how to deal with this"
	exit 1
else
	echo "ERROR: unrecognized read-out mode"
	exit 1
fi

# -----------------------------------------------------
# Move magnitude and phase images to result folder
# -----------------------------------------------------
cd $OCD
mv -f $1/fmap_mag1.nii   		$WDIR
mv -f $1/fmap_mag2.nii   		$WDIR
mv -f $2/fmap_phase1.nii 		$WDIR
mv -f $2/fmap_phase2.nii 		$WDIR
mv -f $2/b0map.shims 	 		$WDIR

# -----------------------------------------------------
# Do BET or T1 coregister to get brain mask
# -----------------------------------------------------

# --- Coregister whole brain struct to fmap magnitude image ---
if [ -n "$t1whole" ]; then
	echo "Coregistering T1head to B0map magnitude image."
    cd $OCD
    T1orient=`@GetAfniOrient $t1whole 2> /dev/null`
    B0orient=`@GetAfniOrient $WDIR/fmap_mag1.nii 2> /dev/null`
    if [ $T1orient != $B0orient ]; then
        echo "ERROR: T1head orientation ($T1orient) does not match b0map orientation ($B0orient). Don't want to flirt them."
        exit 1
    fi
    flirt -in $t1whole -ref $WDIR/fmap_mag1.nii -o $WDIR/t1head_in_fmap  -omat $WDIR/t1_to_fmap.mat -dof 6 
    flirt -in $t1brain -ref $WDIR/fmap_mag1.nii -o $WDIR/t1brain_in_fmap -init $WDIR/t1_to_fmap.mat -applyxfm
    fslmaths $WDIR/fmap_mag1 -mas $WDIR/t1brain_in_fmap $WDIR/fmap_mag1_brain.nii
    MAGFILE=fmap_mag1_brain.nii

# --- skull strip with BET ---
elif [ $do_skullstrip = "1" ]; then
	echo "Skull stripping with BET."
	cd $WDIR
	rm -f fmap_mag1_brain.nii
	bet fmap_mag1.nii fmap_mag1_brain.nii  -f ${bet_f} -g ${bet_g} -R
	MAGFILE=fmap_mag1_brain.nii

# --- Use provided brain mask ---
elif [ -n "$brainmask" ]; then
    cd $OCD
    fslmaths fmap_mag1 -mas $brain_mask fmap_mag1_brain.nii
    MAGFILE=fmap_mag1_brain.nii

# --- No brain mask desired, use raw magnitude fmap ---
else
	MAGFILE=fmap_mag1.nii
fi

# -----------------------------------------------------
# Compute fieldmap
# -----------------------------------------------------
cd $OCD
cd $WDIR
echo "Calculating fieldmap."

# --- Convert integer Dicom phase images to radians ---
# --- (Note: FSL's prelude doesn't care if maps are [0,2pi] or [-pi,pi])
rm -f fmap_rad1.nii fmap_rad2.nii 
if [ $readout = "monopolar" ]; then
    fslmaths fmap_phase1 -mul 3.14159 -div 2048 -sub 3.14159 fmap_rad1 -odt float
    fslmaths fmap_phase2 -mul 3.14159 -div 2048 -sub 3.14159 fmap_rad2 -odt float
else
    echo "BIPOLAR"
 #   3dLRflip -prefix fmap_phase2_flip.nii fmap_phase2.nii # this aint it
    fslmaths fmap_phase1 -mul -3.14159 -div 2048 -add 3.14159 fmap_rad1 -odt float
    fslmaths fmap_phase2 -mul  3.14159 -div 2048 -sub 3.14159 fmap_rad2 -odt float
fi

# --- compute complex ratio of TE1 and TE2 images ---
# --- doing only one Prelude call works better (less wrap boundary errors) ---
# --- Use AFNI because "fslcomplex" has some bug which switches A->P ---
rm -f a.nii b.nii c.nii d.nii radmap.nii
3dcalc -a $MAGFILE -b fmap_rad1.nii -expr 'a*cos(b)' -prefix a.nii -datum float &> /dev/null
3dcalc -a $MAGFILE -b fmap_rad1.nii -expr 'a*sin(b)' -prefix b.nii -datum float &> /dev/null
3dcalc -a $MAGFILE -b fmap_rad2.nii -expr 'a*cos(b)' -prefix c.nii -datum float &> /dev/null
3dcalc -a $MAGFILE -b fmap_rad2.nii -expr 'a*sin(b)' -prefix d.nii -datum float &> /dev/null
3dcalc -a a.nii -b b.nii -c c.nii -d d.nii -expr '-atan2(b*c-a*d,a*c+b*d)' -prefix radmap.nii -datum float &> /dev/null

# --- Unwrap delta_phase image ---
rm -f radmap_unwrap.nii mask.nii
prelude -a $MAGFILE -p radmap -o radmap_unwrap --savemask=mask

# --- compare to FSL's recommended method: separately unwrap, then subtract phase maps ---
# --- CONCLUSION: same result but better to do only one PRELUDE ---
#rm -f fmap_rad1_unwrap.nii fmap_rad2_unwrap.nii b0mapX.nii radmapX.nii
#prelude -v -a $MAGFILE -p fmap_rad1 -o fmap_rad1_unwrap 
#prelude -v -a $MAGFILE -p fmap_rad2 -o fmap_rad2_unwrap 
#fslmaths fmap_rad2_unwrap -sub fmap_rad1_unwrap -mul 1000 -div $dTE -div 6.28318 hzmapX - odt float	# x1000/msec/2/PI = Hz
#fslmaths fmap_rad2_unwrap -sub fmap_rad1_unwrap -mul 1000 -div $dTE              rpsmapX -odt float	# x1000/msec = rad/sec

# --- Convert phase difference image to Hz and radians/sec ---
rm -f hzmap.nii rpsmap.nii
fslmaths radmap_unwrap -mul 1000 -div $dTE -div 6.28318 hzmap  -odt float	# x1000/msec/2/PI = Hz
fslmaths radmap_unwrap -mul 1000 -div $dTE              rpsmap -odt float	# x1000/msec = radians/sec

# --- Use FUGUE to fill holes ---
mv -f rpsmap.nii rpsmap_prefill.nii; fugue --loadfmap=rpsmap_prefill --mask=mask         --savefmap=rpsmap
mv -f mask.nii mask_prefill.nii;     fugue --loadfmap=mask_prefill   --mask=mask_prefill --savefmap=mask

# --- Remove mean from rpsmap ---
if [ $do_demean = "1" ]; then
	echo "De-meaning rpsmap."
	mv -f rpsmap.nii rpsmap_nzmean.nii
	demean_image rpsmap_nzmean mask rpsmap
fi

# --- Remove spikes from the edges of the rpsmap ---
if [ $do_despike = "1" ]; then
	echo "De-spiking edges of rpsmap."
	mv -f rpsmap.nii rpsmap_predespike.nii
	clean_up_edge rpsmap_predespike mask rpsmap
fi

# --- clean up ---
if [ $keep_files -eq 0 ]; then
	rm -f a.nii b.nii c.nii d.nii fmap_rad1.nii fmap_rad2.nii fmap_phase1.nii fmap_phase2.nii radmap.nii 
	rm -f radmap_unwrap.nii rpsmap_nzmean.nii rpsmap_predespike.nii rpsmap_prefill.nii mask_prefill.nii t1head_in_fmap.nii t1brain_in_fmap.nii t1_to_fmap.mat
#	rm -f fmap_rad1_unwrap.nii fmap_rad2_unwrap.nii b0mapX.nii radmapX.nii
fi

cd $OCD
echo "Done."
exit 0
