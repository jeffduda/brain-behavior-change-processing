#!/bin/bash
#
# calculate some QA matrics from a 3D structural (i.e. MPRAGE)
#
# gets mean signal from strict AFNI automask
# gets noise stdev from non-signal mask
#
# MElliott Feb, 2012


export FSLOUTPUTTYPE=NIFTI
export AFNI_AUTOGZIP=NO
export AFNI_COMPRESSOR=

# --- Check input args ---
if [ $# -lt 2 ]; then
	echo "usage: $0 <3DNifti_file> <results_file>"
	exit 1
fi
infile=$1
outfile=$2

# --- get size of structural ---
diminfo=`fslinfo $infile | grep -w dim1`
set -- $diminfo
NX=$2
echo NX = $2
diminfo=`fslinfo $infile | grep -w dim2`
set -- $diminfo
NY=$2
echo NY = $NY
diminfo=`fslinfo $infile | grep -w dim3`
set -- $diminfo
NZ=$2
echo NZ = $NZ

# --- max x,y,z coords (AFNI counts [0,nx-1]) ---
x1=$(expr $NX - 1)
y1=$(expr $NY - 1)
z1=$(expr $NZ - 1)
#echo x1 = $x1
#echo y1 = $y1
#echo z1 = $z1

# --- make signal mask from structural ---
rm -f mask1.nii
3dAutomask -clfrac 0.7 -prefix mask1.nii -erode 2 $infile	# stricter clip level and 2 erodes = small mask

# --- make not-signal mask from structural ---
# --- (exclude signal and borders of image) ---
rm -f mask2.nii
3dAutomask -clfrac 0.3 -prefix mask2.nii -dilate 10 $infile	 # liberal clip level and 2 dilates = big mask
rm -f mask3.nii
3dcalc -a mask2.nii -expr "and( not(a), not(equals(i,0)), not(equals(j,0)), not(equals(k,0)), not(equals(i,$x1)), not(equals(j,$y1)), not(equals(k,$z1)) ) "  -prefix mask3.nii

# ---- do SUSAN to structural ---
susanfile=susantest.nii
rm -f $susanfile
susan $infile -1 6 3 0 0 $susanfile

# --- get difference between struct and SUSAN result ---
susandiff=susandiff.nii
rm -f susandiff.nii
fslmaths $infile -sub $susanfile $susandiff

# --- now get signal stats over masks ---
sigmean1=`3dmaskave -q -mask mask1.nii $infile`			# Mean signal in MPRAGE
echo "signal_mean = $sigmean1" > $outfile

results=`3dmaskave -q -sigma -mask mask3.nii $infile`	# STDEV of noise in MPRAGE
set -- $results
sigstdev1=$2
echo "noise_stdev = $sigstdev1" >> $outfile

sigmean2=`3dmaskave -q -mask mask1.nii $susandiff`			# Mean signal of (MPRAGE-SUSAN) in signal region
echo "diffsignal_mean = $sigmean2" >> $outfile

sigmean3=`3dmaskave -q -mask mask3.nii $susandiff`			# Mean signal of (MPRAGE-SUSAN) in noise region
echo "diffnoise_mean = $sigmean3" >> $outfile

results=`3dmaskave -q -sigma -mask mask1.nii $susandiff`	# STDEV of (MPRAGE-SUSAN) in signal region
set -- $results
sigstdev2=$2
echo "diffsignal_stdev = $sigstdev2" >> $outfile

results=`3dmaskave -q -sigma -mask mask3.nii $susandiff`	# STDEV of (MPRAGE-SUSAN) in noise region
set -- $results
sigstdev3=$2
echo "diffnoise_stdev = $sigstdev3" >> $outfile

# --- Compute some SNR metrics ---
snr=`echo "scale=4; $sigmean1 / $sigstdev1" | bc`	# do floating point math using "bc" command
echo "snr = $snr"  >> $outfile

snr1=`echo "scale=4; $sigmean1 / $sigstdev2" | bc`	
echo "snr1 = $snr1"  >> $outfile

snr2=`echo "scale=4; $sigmean1 / $sigstdev3" | bc`	
echo "snr2 = $snr2"  >> $outfile

exit 0
