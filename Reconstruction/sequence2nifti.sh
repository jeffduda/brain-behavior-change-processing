#!/bin/bash
# ---------------------------------------------------------------
# SEQUENCE2NIFTI.sh
#
# Wrapper program for "dicom2nifti.sh"
# Designed to call "dicom2nifti.sh" with appropriate switches/options 
#   for specific MRI Sequence types (e.g. DTI, Strutural, BOLD, ...)
#
# NOTE: expects supplied dicoms to be sorted/named in proper order by image number!
#
#
# MElliott 12/2012
# ---------------------------------------------------------------

# --- print how to call this thing ---
Usage() {
cat << EOF
USAGE: `basename $0` OPTION outfile dcmfile1 [dcmfile2 ... dcmfileN] 
  where OPTION is one of:
    B0MAP           Convert b0map (NOTE: expects dicoms from 2 series!)
    BOLD            Convert BOLD data, preserving obliqueness if any
    BOLD_DEOBLIQUE  Convert BOLD data, deobliquing if needed
    DTI             Convert DTI data, extract bvals & bvecs
    DTI_CONCAT      Convert DTI data from multiple series, concatenating 4D Nifti + bvec and bval files
    DTI_OBLIQUE     Convert DTI data, extract bvals & bvecs, preserve obliqueness if any
    DWI             Convert DWI data (e.g. non-mosaic'd 3-scan trace)
    NAV_MPRAGE      Convert the navigator series from moco_mprage
    PCASL           Convert pCASL data
    STRUCTURAL      Convert Structural data (e.g. MPRAGE)
        NOTE: You can append "_RPI" to any of these options.
EOF
exit 1
}

# --- Figure out path to other scripts in same place as this one ---
EXECDIR=`dirname $0`
if [ "X${EXECDIR}" != "X" ]; then
    OCD=$PWD; cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD # makes path absolute
fi

# --- Parse command line ---
if [ $# -lt 3 ]; then Usage; fi
option=$1
outfile=$2
shift
shift

# --- Execute dicom->nifti with appropriate switches ---
case $option in 
    # Call special script. NOTE: expects dicom files from BOTH series created by this sequence!
    B0MAP)          ${EXECDIR}dico_b0calc_v3.sh -Samx2 $outfile $@ ;;
    
    # Call special script. NOTE: expects dicom files from BOTH series created by this sequence!
    B0MAP_RPI)          ${EXECDIR}dico_b0calc_v3.sh -FSamx2 $outfile $@ ;;
    
    # force (note slice-timing correction removed for QA!)
    BOLD)           ${EXECDIR}dicom2nifti.sh -e $outfile $@ ;;

    # force RPI (note slice-timing correction removed for QA!)
    BOLD_RPI)       ${EXECDIR}dicom2nifti.sh -Fe $outfile $@ ;;

    # Do deoblique
    BOLD_DEOBLIQUE) ${EXECDIR}dicom2nifti.sh -tde $outfile $@ ;;

    # Do deoblique, and force RPI
    BOLD_DEOBLIQUE_RPI) ${EXECDIR}dicom2nifti.sh -tdFe $outfile $@ ;;

    # Use dcm2nii since it gets bvals/bvecs. MIGHT be a problem with obliques, but so far ALL DTI is straight axial   
    DTI|DTI_RPI)    ${EXECDIR}dicom2nifti.sh -ue $outfile $@ ;;
    
    # Concatenate multiple series of DTI dicoms, create single 4D w/ concatenated data, bval and bvec files   
    DTI_CONCAT|DTI_CONCAT_RPI) ${EXECDIR}dicom2nifti.sh -ume $outfile $@ ;;
    
    # this works for oblique DTI - first convert w/ dcm2nii just for bvals/bvecs, then remake Nifti w/ to3d
    DTI_OBLIQUE)    ${EXECDIR}dicom2nifti.sh -u $outfile $@
                    ${EXECDIR}dicom2nifti.sh -Fe $outfile $@ ;;
    
    # this works for oblique DTI - first convert w/ dcm2nii just for bvals/bvecs, then remake Nifti w/ to3d
    DTI_OBLIQUE_RPI) ${EXECDIR}dicom2nifti.sh -u $outfile $@
                    ${EXECDIR}dicom2nifti.sh -e $outfile $@ ;;
    
    # Use dcm2nii since DWI are not mosaic'd (to3d doesn't figure out 4D w/o mosaic)   
    DWI|DWI_RPI)    ${EXECDIR}dicom2nifti.sh -ue $outfile $@ ;;
    
    # convert navigators from moco_mprage (strange dicoms - only dcm2nii works!)
    NAV_MPRAGE|NAV_MPRAGE_RPI)    ${EXECDIR}dicom2nifti.sh -ue $outfile $@ ;;
    
    # for pCASL, don't want slice time correction
    PCASL)          ${EXECDIR}dicom2nifti.sh -e $outfile $@ ;;
    
    # for pCASL RPI, don't want slice time correction
    PCASL_RPI)      ${EXECDIR}dicom2nifti.sh -Fe $outfile $@ ;;
    
    # convert a structural and leave in native orientation
#    STRUCTURAL)     ${EXECDIR}dicom2nifti.sh -eu $outfile $@ ;;  # using "-u" will make axials RPI, but leave sag and cor as is
    STRUCTURAL)     ${EXECDIR}dicom2nifti.sh -e $outfile $@ ;;  

    # convert a structural and force RPI
    STRUCTURAL_RPI) ${EXECDIR}dicom2nifti.sh -Fe $outfile $@ ;;
    
    *) echo "ERROR: Unrecognized OPTION: ${option}."; Usage; ;;
esac

exit 0
