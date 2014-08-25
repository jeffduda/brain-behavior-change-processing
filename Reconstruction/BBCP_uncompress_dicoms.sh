#!/bin/bash
# ---------------------------------------------------------------
# uncompress Dicoms previously compressed with BBCP_compress_dicoms.sh

# --- Parse command line ---
if [ $# -ne 1 ]; then
	echo "usage: $0 <Subjects_dir/>"
	exit 1
fi

cd $1
topdir=$PWD # this makes the path absolute (not relative).

for dcmdir in $(ls -d 00*/Images/S*/Dicoms)
do
	cd $dcmdir
	if [ -e dicoms.tgz ]; then
		echo Uncompressing $dcmdir
		tar xfz dicoms.tgz
		if [ $? -eq 0 ]; then rm -f dicoms.tgz; fi
	fi
	cd $topdir
done

echo "Done."
exit 0
