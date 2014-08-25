#!/bin/bash
# ---------------------------------------------------------------
# dicom_get_pedir.sh
#
# Gets the "pedir" parameter for FSL's fugue and epi_reg
# i.e. the phase encoding direction ( = x,y,-x,-y,-z )
# 
# ---------------------------------------------------------------

Usage() {
    echo ""
    echo "Usage: `basename $0` dicomfile"
    echo ""
    exit 1
}

if [ $# -ne 1 ]; then
    Usage
fi

dcminfo=(`dicom_hdr $1 2>/dev/null | grep -i "0018 1312"`)
np=${#dcminfo[@]}
PEDIR=`echo ${dcminfo[$np-1]} | tr -d 'Direction//'`
! (dicom_hdr -sexinfo $example_dicom | grep -q "dInPlaneRot") 2> /dev/null
PEREVERSED=$?   # phase encoding direction is rotated (i.e. A->P becomes P->A) 
if [ $PEDIR = "ROW" ]; then
	UNWARP_DIR="x"
elif [ $PEDIR = "COL" ]; then
	UNWARP_DIR="y"	
else
	echo "ERROR: Strange PEDIR value: $PEDIR"
	exit 1
fi
if [ $PEREVERSED -eq 0 ]; then
#	UNWARP_DIR=-${UNWARP_DIR}
	UNWARP_DIR=${UNWARP_DIR}-   # syntax compatible with FUGUE and EPI_REG 
fi

echo $UNWARP_DIR

exit 0
