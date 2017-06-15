#!/bin/bash

ctDir=$1 #assumes files begin with highRes_
blurMask=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500/DNS500_cauc568_BlurMask30.nii.gz


cd $ctDir

antsApplyTransforms -d 3 -e 3 -i ${ctDir}/highRes_BrainSegmentationPosteriors2.nii.gz -o ${ctDir}/tmp.gmWarped.nii.gz -r ${ctDir}/highRes_CorticalThicknessNormalizedToTemplate.nii.gz -t ${ctDir}/highRes_SubjectToTemplate1Warp.nii.gz -t ${ctDir}/highRes_SubjectToTemplate0GenericAffine.mat 

antsApplyTransforms -d 3 -e 3 -i ${ctDir}/highRes_BrainSegmentationPosteriors4.nii.gz -o ${ctDir}/tmp.subCortWarped.nii.gz -r ${ctDir}/highRes_CorticalThicknessNormalizedToTemplate.nii.gz -t ${ctDir}/highRes_SubjectToTemplate1Warp.nii.gz -t ${ctDir}/highRes_SubjectToTemplate0GenericAffine.mat 

antsApplyTransforms -d 3 -e 3 -i ${ctDir}/highRes_BrainSegmentationPosteriors6.nii.gz -o ${ctDir}/tmp.cerWarped.nii.gz -r ${ctDir}/highRes_CorticalThicknessNormalizedToTemplate.nii.gz -t ${ctDir}/highRes_SubjectToTemplate1Warp.nii.gz -t ${ctDir}/highRes_SubjectToTemplate0GenericAffine.mat

antsApplyTransforms -d 3 -e 3 -i ${ctDir}/highRes_BrainSegmentationPosteriors5.nii.gz -o ${ctDir}/tmp.bsWarped.nii.gz -r ${ctDir}/highRes_CorticalThicknessNormalizedToTemplate.nii.gz -t ${ctDir}/highRes_SubjectToTemplate1Warp.nii.gz -t ${ctDir}/highRes_SubjectToTemplate0GenericAffine.mat 

3dcalc -a ${ctDir}/tmp.gmWarped.nii.gz -b ${ctDir}/tmp.subCortWarped.nii.gz -c ${ctDir}/tmp.cerWarped.nii.gz -d $blurMask -e ${ctDir}/tmp.bsWarped.nii.gz -expr 'a*equals(d,1)+b*equals(d,2)+c*equals(d,3)+e*equals(d,4)' -prefix ${ctDir}/tmp.antsVBM_noMod.nii.gz
3dcalc -a ${ctDir}/tmp.gmWarped.nii.gz -b ${ctDir}/tmp.subCortWarped.nii.gz -c ${ctDir}/tmp.cerWarped.nii.gz -d $blurMask -e ${ctDir}/highRes_SubjectToTemplateLogJacobian.nii.gz -f ${ctDir}/tmp.bsWarped.nii.gz -expr '(a*equals(d,1)+b*equals(d,2)+c*equals(d,3)+f*equals(d,4))*e' -prefix ${ctDir}/tmp.antsVBM_jacMod.nii.gz

3dBlurInMask -input ${ctDir}/tmp.antsVBM_noMod.nii.gz -FWHM 8 -Mmask $blurMask -prefix ${ctDir}/antsVBM_noMod_blur8mm.nii.gz
3dBlurInMask -input ${ctDir}/tmp.antsVBM_jacMod.nii.gz -FWHM 8 -Mmask $blurMask -prefix ${ctDir}/antsVBM_jacMod_blur8mm.nii.gz

3drefit -space MNI -view tlrc ${ctDir}/antsVBM_*
rm ${ctDir}/tmp.*
