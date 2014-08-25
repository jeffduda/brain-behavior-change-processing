#!/bin/sh
# This script will call the matlab executable with this script's name
#   i.e. "dicom_dump.sh" will execute "dicom_dump"
#
# M.Elliott 3/2014

edir=`dirname $0`

eval ${edir}/matbin_wrapper.sh $0 $@
status=$?
exit $status

