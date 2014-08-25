#!/bin/bash
# ---------------------------------------------------------------
# PROTOCOL2NIFTI.sh
#
# Wrapper program for "sequence2nifti.sh"
# Designed to call "sequence2nifti.sh" with appropriate switches/options 
#
# NOTE: 1) expects supplied dicoms to be sorted/named in proper order by image number!
#       2) This script is very specific to how each series folder was named when it was extracted/sorted!!
#           e.g. XNAT, dicom_MFsort, ...
#
#
# MElliott 7/2013
# ---------------------------------------------------------------

# --- print how to call this thing ---
# --- print how to call this thing ---
Usage() {
cat << EOF
USAGE: `basename $0` PROTOCOL topdir/ 
     or
       `basename $0` PROTOCOL seqdir1/ seqdir2/ [seqdir3/ ... seqdirN/] 
  where PROTOCOL is one of:
    BBCP BBL MARK MARK_NORPI
EOF
exit 1
}

# --- Figure out path to other scripts in same place as this one ---
EXECDIR=`dirname $0`
if [ "X${EXECDIR}" != "X" ]; then
    OCD=$PWD; cd ${EXECDIR}; EXECDIR=${PWD}/; cd $OCD # makes path absolute
fi

# --- Parse command line ---
if [ $# -lt 1 ]; then Usage; fi
protocol=$1
shift
if [ $# -eq 1 ]; then
    dirlist=`ls -d $1/*`
else
    dirlist=$@
fi

# --- set what subfolder NIFTIs will be written to ---
forceRPI=1
case $protocol in
    BBCP)   NIFDIR="NIFTIs"
            DCMDIR="Dicoms" ;;

    BBL)    NIFDIR="."
            DCMDIR="." ;;

    MARK)    NIFDIR="."
            DCMDIR="." ;;

    MARK_NORPI)    NIFDIR="."
            DCMDIR="." 
            forceRPI=0;;

    *) echo "ERROR: Unrecognized PROTOCOL: ${protocol}."; Usage; exit 1 ;;
esac

# --- Execute sequence2nifti with appropriate options ---
last_type="XXX"
last_seqroot="XXX"
for seqdir in $dirlist ; do 
    if [ ! -d $seqdir ]; then
        echo "$seqdir is not a directory. Ignoring it."
    else
    seqroot=`basename $seqdir`
            
    # --- Handle known sequences by sequence folder name ---    
    case $seqroot in
        S0*_MPRAGE_NAV*)
            type="NAV_MPRAGE"
            niftifile="$seqdir/$NIFDIR/mprage_nav.nii"
            ;;

        S0*_mprage_*|S0*_MPRAGE_*|S0*_mp2rage_*|S0*_MP2RAGE_*|S0*_PD_*)
            type="STRUCTURAL"  
            niftifile="$seqdir/$NIFDIR/mprage.nii"
            ;;

        S0*_T2_*)
            type="STRUCTURAL"  
            niftifile="$seqdir/$NIFDIR/t2.nii"
            ;;

        S0*_bbl1_*|S0*_bbcc1_*)
            type="BOLD" 			
            niftiroot=`echo $seqroot | cut -d_ -f 2,3,4,5,6,7`      # peel off bold task name
			niftifile="$seqdir/$NIFDIR/${niftiroot}.nii"
            ;;

        S0*_BOLD*|S0*_Bold*|S0*_bold*|S0*_RestingBOLD*|S0*_restingBOLD*)
            type="BOLD" 			
 			niftifile="$seqdir/$NIFDIR/bold.nii"
            ;;

        S0*_ep2d_pcasl*|S0*_ep2d_se_pcasl*|S0*_pcasl_se*)
			type="PCASL"     
            niftifile="$seqdir/$NIFDIR/pcasl.nii"
            ;;

        S0*_DTI_64Combined*)
            type="DTI"
            niftifile="$seqdir/$NIFDIR/dti.nii"
            ;;

        S0*_DTI_2x32_35)
            type="WAIT_DTI"
            niftifile=""
            ;;

        S0*_DTI_2x32_36)
            if [ $last_type == "WAIT_DTI" ]; then
                type="DTI_CONCAT"
		        niftifile="$last_seqdir/$NIFDIR/dti_merged.nii"
            else
                type="MISSING_DTI"
                niftifile=""
            fi
            ;;

        S0*_B0map_*|S0*_b0map*|S0*_B0map|S0*_b0map)
            if [ $last_type == "WAIT_B0MAP" ]; then
                type="B0MAP"
                niftifile="$last_seqdir/$NIFDIR/b0map_mask.nii"
            else
                type="WAIT_B0MAP"
                niftifile=""
            fi
            ;;

        *) 	type="IGNORE"
            niftifile=""
		   	;;
    esac

    # --- Check if NIFTI file already exists ---
    if [ ! -z $niftifile ]; then
        if [ -e $niftifile ]; then type="EXISTS"; fi
    fi

    # --- Now convert to NIFTI ---    
    case $type in 
        IGNORE)
            echo "Ignoring unrecognized directory $seqdir" 
            ;;
    
        EXISTS)
			echo "$niftifile already exists. Skipping it."						
            ;;

        MISSING_DTI)
            echo "ERROR: Found $seqroot, but previous folder is not DTI!"
            ;;
    
        WAIT_B0MAP)
            echo "Found $seqroot - will wait for second B0map directory"
            ;;  
        
        WAIT_DTI)
            echo "Found $seqroot - will wait for second DTI directory"
            ;;
        
        DTI_CONCAT)
			echo "Converting $last_seqroot/ and $seqroot/ to NIFTI type $type"
            ${EXECDIR}sequence2nifti.sh $type $niftifile $last_seqdir/$DCMDIR/*.dcm $seqdir/Dicoms/*.dcm 
            ;;

        B0MAP)
            if [ $forceRPI -eq 1 ]; then type=${type}_RPI; fi
			echo "Converting $last_seqroot/ and $seqroot/ to NIFTI type $type"
            ${EXECDIR}sequence2nifti.sh $type $last_seqdir/$NIFDIR/b0map $last_seqdir/$DCMDIR/*.dcm $seqdir/$DCMDIR/*.dcm 
            ;;

        *)  if [ $forceRPI -eq 1 ]; then type=${type}_RPI; fi
            echo "Converting $seqroot/ to NIFTI type $type"
			${EXECDIR}sequence2nifti.sh $type $niftifile $seqdir/$DCMDIR/*.dcm 
            ;;
    esac

    last_seqdir=$seqdir
    last_seqroot=$seqroot
    last_type=$type
    fi
	echo "---------------------------------------------------"
 done 


exit 0
