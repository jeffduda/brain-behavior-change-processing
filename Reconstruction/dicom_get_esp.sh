#!/bin/bash
# ---------------------------------------------------------------
# dicom_get_esp.sh
#
# Gets the echo-spacing (in seconds) from a dicom file of EPI data
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

dcminfo=(`dicom_hdr -sexinfo $1 2>/dev/null | grep "sPat.lAccelFactPE"`)
np=${#dcminfo[@]}
GRAPPA=${dcminfo[$np-1]}
dcminfo=(`dicom_hdr -sexinfo $1 2>/dev/null | grep "lEchoSpacing"`)

if [ $? -eq 0 ] ; then	# ESP only stored in header for user-chosen ESP
	np=${#dcminfo[@]}
	ESP=${dcminfo[$np-1]}
	ESP=`echo "scale=6; $ESP /1000000" | bc`	# use 'bc' to do math - convert usec to sec
else
	dcminfo=(`dicom_hdr -sexinfo $1 2>/dev/null | grep "Pixel Bandwidth"`)
	np=${#dcminfo[@]}
	PBW=`echo ${dcminfo[$np-1]} | tr -d 'Bandwidth//'`
#	echo PBW = $PBW
	ESP=`echo "scale=6; 1/$PBW + 0.000082" | bc`	# use 'bc' to do math - convert pixbw to esp in sec
fi									
ESP_COR=`echo "scale=6; $ESP/$GRAPPA" | bc`

echo $ESP_COR
exit 0
