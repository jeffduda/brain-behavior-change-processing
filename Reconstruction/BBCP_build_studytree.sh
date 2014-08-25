#!/bin/bash
# ---------------------------------------------------------------
# BBCP_build_studytree.sh - build directory structure around sorted dicoms
#
# Written by M.Elliott 

# -------------------------------
function create_dir
{	
	if [ ! -d ${1} ]; then 
		echo "Creating $PWD/$1"
		mkdir $1
	fi
}

# ---------------------------------------------------------------
# --- MAIN routine starts here ---
# ---------------------------------------------------------------

# --- Parse command line ---
if [ $# -lt 1 ]; then
	echo "usage: $0 <toplevel_dir/>"
	exit 1
fi

cd $1

create_dir "Templates"
create_dir "Designs"
create_dir "Scripts"
create_dir "Docs"
create_dir "Manuscripts"
create_dir "Figures"
create_dir "Subjects"
create_dir "GroupResults"

# move each sorted Dicom folder to Subjects
shopt -s nullglob # prevents no-file-match problem below
for folder in $(ls -d 00*)
do	
    if [ $folder != "." ]; then	
	echo "Moving $folder to Subjects/"
	mv $folder Subjects/
    fi
done

# populate each subject/session folder
cd Subjects/
for subjfolder in $(ls -d 00*)
do	
    if [ $subjfolder != "." ]; then	
	cd $subjfolder
	create_dir "Info"
	create_dir "Images"
	
	mv series_info.log Images/
	mv S0*             Images/

	cd Images/
	for seqfolder in $(ls -d S0*)
	do
		cd $seqfolder
		create_dir "NIFTIs"
		create_dir "QA"
		create_dir "Behavior"
		create_dir "Results"
		cd ../
	done	
	cd ../		# out of Images/
	cd ../		# out of 00*/
   fi 
done
cd ../

echo "Done."
exit 0

