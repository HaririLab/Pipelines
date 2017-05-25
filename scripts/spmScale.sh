#!/bin/bash

#
# Script: spmScale.sh
# Purpose:Calculate SPM type scaling for a warped epi Image. For comparison between pipelines
# Author: Maxwell Elliott
# Date: 4/03/17

epi=$1
outDir=$2


3dBlurInMask -input ${epi} -mask /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500/DNS500template_MNI_BrainExtractionMask_2mmDil1.nii.gz -FWHM 6 -prefix ${outDir}/tmp.epiWarped_spmblur6mm.nii.gz
3dTstat -prefix ${outDir}/tmp.mean.epiWarped_blur6mm.nii.gz ${outDir}/tmp.epiWarped_spmblur6mm.nii.gz
gm=$(3dROIstats -quiet -mask /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz ${outDir}/tmp.mean.epiWarped_blur6mm.nii.gz | cut -d " " -f6)
3dcalc -a ${outDir}/tmp.epiWarped_spmblur6mm.nii.gz -expr "min(200, a/${gm}*100)*step(a)" -prefix ${outDir}/epiWarped_spmScaledBlur6mm.nii.gz
rm ${outDir}/tmp.epiWarped_spmblur6mm.nii.gz ${outDir}/tmp.mean.epiWarped_blur6mm.nii.gz
