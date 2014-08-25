#!/bin/bash
# dump nifti Sforms and Qforms from headers

Usage() {
    echo ""
    echo "Usage: `basename $0` nifti_file1 [nifti_file2 ... nifti_fileN]"
    echo ""
    exit 1
}
if [ $# -lt 1 ]; then
    Usage
fi

echo ""
echo "QFORM"
for file in $@ ; do
    xform=`fslorient -getqform $file`
    xform=`printf "%1.1f  " $xform`
    xform=${xform//-0.0/0.0}
    echo -e "$xform\t $file"   
done

echo ""
echo "SFORM"
for file in $@ ; do
    xform=`fslorient -getsform $file`
    xform=`printf "%1.1f  " $xform`
    xform=${xform//-0.0/0.0}
    echo -e "$xform\t $file"   
done

echo ""
echo "ORIENT"
for file in $@ ; do
    fullfile=`imglob -extension $file`
    orient_code=`@GetAfniOrient $fullfile 2> /dev/null`
    echo -e "$orient_code \t $file"   

done

rm -f junkjunk
exit 0
