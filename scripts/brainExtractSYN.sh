#!/bin/bash

#Author: Max Elliott, 1/24/17

##Skull strips with antsSYN based registration. Seems to perform better than other skull stripping. Michael and HCP both endorse this method

##Naming conventions are meant to reflect antsCT so that this script can replace the Skull stripping in that pipeline. antsCorticalThickness.sh 
##should skip over N4 and skull stripping if this scrip was previously run in the same dir adn the same prefix was used

head=$1 #image to be skull stripped
template=$2 #template, ideally an ANTs average or something that the head is close to or rigidly aligned to
templateBM=$3 #Brain and Cerebellum extraction mask for template, ideally a very good mask that has been dilated by about 1mm
prefix=$4 #file names will be $prefix_brainMask.nii.gz and $prefix_brain, all other temporary files are removed
threads=$5

#run N4 just in case
N4BiasFieldCorrection -i $head

#register and Extract
antsRegistrationSyN.sh -d 3 -f $head -m $template -n $threads -o ${prefix}temp
antsApplyTransforms -d 3 -i $templateBM -r $head -t ${prefix}temp1Warp.nii.gz -t ${prefix}temp0GenericAffine.mat -n NearestNeighbor -o ${prefix}temp.BrainExtractionMask.nii.gz
3dcalc -a ${prefix}temp.BrainExtractionMask.nii.gz -b $head -expr 'a*b' -prefix ${prefix}temp.Brain.nii.gz
3dAutomask -prefix ${prefix}BrainExtractionMask.nii.gz ${prefix}temp.Brain.nii.gz
3dcalc -a ${prefix}BrainExtractionMask.nii.gz -b $head -expr 'a*b' -prefix ${prefix}Brain.nii.gz

###Remove temp files
rm ${prefix}temp*
