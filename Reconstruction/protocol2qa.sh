#!/bin/bash
# ---------------------------------------------------------------
# PROTOCOL2NIFTI.sh
#
# Designed to call correct QA scripts for each MRI modality
#
# MElliott 7/2013
# ---------------------------------------------------------------

# --- print how to call this thing ---
Usage() {
cat << EOF
USAGE: `basename $0` PROTOCOL <overwrite (0 or 1)> topdir/ 
     or
       `basename $0` PROTOCOL <overwrite (0 or 1)> seqdir1/ seqdir2/ [seqdir3/ ... seqdirN/] 
  where PROTOCOL is one of:
    BBCP BBL
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
protocol=$1
shift
overwrite=$1
shift
if [ $# -eq 1 ]; then
    dirlist=`ls -d $1/*`
else
    dirlist=$@
fi

# --- set what subfolder NIFTIs will be found and written to ---
case $protocol in
    BBCP)   NIFDIR="NIFTIs"
            QADIR="QA" ;;

    BBL)    NIFDIR="."
            QADIR="." ;;

    *) echo "ERROR: Unrecognized PROTOCOL: ${protocol}."; Usage; exit 1 ;;
esac

# --- Execute QA scripts with appropriate options ---
for seqdir in $dirlist ; do 
    if [ ! -d $seqdir ]; then
        echo "$seqdir is not a directory. Ignoring it."
    else
    seqroot=`basename $seqdir`
            
    # --- Handle known sequences by sequence folder name ---    
    case $seqroot in
        S0*_bbl1_*|S0*_bbcc1_*)
            type="BOLD" 			
            niftiroot=`echo $seqroot | cut -d_ -f 2,3,4,5,6,7`      # peel off bold task name
			niftifile="$seqdir/$NIFDIR/${niftiroot}.nii"
			qafile="$seqdir/$QADIR/${niftiroot}.qa"
            ;;

        S0*_BOLD*|S0*_Bold*|S0_bold*)
            type="BOLD" 			
 			niftifile="$seqdir/$NIFDIR/bold.nii"
			qafile="$seqdir/$QADIR/bold.qa"
            ;;

        S0*_ep2d_pcasl*|S0*_ep2d_se_pcasl*|S0*_pcasl_se*)
			type="PCASL"     
            niftifile="$seqdir/$NIFDIR/pcasl.nii"
            qafile="$seqdir/$QADIR/pcasl.qa"
		    dcmfile=$seqdir/$NIFDIR/pcasl_exampledicom.DCM
            ;;

        S0*_DTI_64Combined*)
            type="DTI"
            niftiroot="dti"
 	        niftifile=$seqdir/$NIFDIR/${niftiroot}.nii
			qafile=$seqdir/$QADIR/${niftiroot}.qa
			bvalfile=$seqdir/$NIFDIR/${niftiroot}.bval
			bvecfile=$seqdir/$NIFDIR/${niftiroot}.bvec
            ;;

        S0*_DTI_2x32_35)
            type="DTI"
            niftiroot="dti_merged"
 	        niftifile=$seqdir/$NIFDIR/${niftiroot}.nii
			qafile=$seqdir/$QADIR/${niftiroot}.qa
			bvalfile=$seqdir/$NIFDIR/${niftiroot}.bval
			bvecfile=$seqdir/$NIFDIR/${niftiroot}.bvec
            ;;

        *) 	type="IGNORE"
            qafile=""
		   	;;
    esac

    # --- Check if QA result file already exists ---
    if [ ! -z $qafile ]; then
        if [ -e $qafile -a $overwrite -eq 0 ]; then 
            type="EXISTS"; 
        elif [ ! -e $niftifile ]; then
            type="MISSING_NIFTI"
        fi
    fi

    # --- Now do the QA ---    
    case $type in 
        IGNORE)
            echo "Ignoring unrecognized directory $seqdir" 
            ;;
    
        EXISTS)
			echo "$qafile already exists. Skipping it."
			echo "     You can set the <overwrite> option to force re-running the QA."						
            ;;

        MISSING_NIFTI)
			echo "ERROR: cannot find $niftifile to QA."						
            ;;

        BOLD)
            echo "Starting BOLD QA on ${niftifile}"
            ${EXECDIR}qa_bold_v1.sh ${niftifile} ${qafile}
            ;;

        DTI)
            echo "Starting DTI QA on ${niftifile}"
			${EXECDIR}qa_dti_v1.sh ${niftifile} ${bvalfile} ${bvecfile} ${qafile}
            ;;

        PCASL)
            echo "Starting PCASL QA on ${niftifile}"
			${EXECDIR}qa_pcasl_v1.sh -example_dicom $dcmfile $niftifile $qafile
           ;;

    esac

    fi
	echo "---------------------------------------------------"
 done 


exit 0
