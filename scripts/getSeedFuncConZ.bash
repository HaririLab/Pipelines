#!/bin/bash

##################################getSeedFuncConZ.bash##############################
####################### Authored by Max Elliott 3/11/2016 ####################

####Description####
#made to speed up the extraction of Z scores from ROIs for purposes of seed diffs and cwas followups. Slow if not run on biowulf

data=$1
seedMask=$2
maskSelector=$3
outWD=$4
prefix=$5

3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $data > $outWD/tmp.$prefix.maskData.1D
3dDeconvolve -quiet -input $data -polort -1 -num_stimts 1 \
	-stim_file 1 tmp.$prefix.maskData.1D -stim_label 1 maskData \
	-tout -rout -bucket $outWD/tmp.$prefix.maskData.decon.nii
3dcalc -a tmp.$prefix.maskData.decon.nii'[4]' -b tmp.$prefix.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix $outWD/tmp.$prefix.maskData.R.nii
3dcalc -a tmp.$prefix.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $outWD/$prefix.maskConnData.Z.nii.gz
rm tmp.${prefix}*
