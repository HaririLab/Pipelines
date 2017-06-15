#!/bin/bash 

# Script: makeTemplateGmMask.sh
# Purpose:Given a list of antCT dirs make a gm mask that can be used for blurring, also prep GM for VBM along the way
# Author: Maxwell Elliott
# Date: 3/14/17

##Assumes typical ANTs naming conventions with highRes_ prefix

template=$1 ##The template T1
prefix=$2 ##Where do you want template GM mask output, what name
VBM=$3 ## T or F, do you want VBM files made for each subject
shift 3
folders=$@  #assumes All_Imaging set up, pass wild card to all subject folders in All_Imaging
echo $prefix
echo $VBM
if [[ ! -f ${prefix}_blurMask10.nii.gz ]];then
	for i in $folders;do
		echo "cd ${i}/antCT;antsApplyTransforms -d 3 -i highRes_BrainSegmentationPosteriors2.nii.gz -t highRes_SubjectToTemplate1Warp.nii.gz -t highRes_SubjectToTemplate0GenericAffine.mat -r $template -o highRes_GMWarpedToTemplate.nii.gz;antsApplyTransforms -d 3 -i highRes_BrainSegmentationPosteriors4.nii.gz -t highRes_SubjectToTemplate1Warp.nii.gz -t highRes_SubjectToTemplate0GenericAffine.mat -r $template -o highRes_subCortWarpedToTemplate.nii.gz;antsApplyTransforms -d 3 -i highRes_BrainSegmentationPosteriors5.nii.gz -t highRes_SubjectToTemplate1Warp.nii.gz -t highRes_SubjectToTemplate0GenericAffine.mat -r $template -o highRes_BSWarpedToTemplate.nii.gz;antsApplyTransforms -d 3 -i highRes_BrainSegmentationPosteriors6.nii.gz -t highRes_SubjectToTemplate1Warp.nii.gz -t highRes_SubjectToTemplate0GenericAffine.mat -r $template -o highRes_CerWarpedToTemplate.nii.gz" >> $prefix.Warp.swarm
	done
	swarmBiac $prefix.Warp.swarm DBIS.01 1
	lenCer=0
	base=$(echo $folders | cut -d " " -f1 | rev | cut -d "/" -f2- | rev | tail -n1)
	num=$(ls ${base}/*/antCT/highRes_BrainSegmentationPosteriors2.nii.gz | wc -l)
	while [ $lenCer -lt $num ];do
		sleep 10
		echo "$lenCer swarm Jobs have completed...Waiting for $num"
		lenCer=$(ls ${base}/*/antCT/highRes_CerWarpedToTemplate.nii.gz | wc -l)
	done

	3dMean -prefix ${prefix}_AvgCerSegWarped.nii.gz ${base}/*/antCT/highRes_CerWarpedToTemplate.nii.gz
	3dMean -prefix ${prefix}_AvgGMSegWarped.nii.gz ${base}/*/antCT/highRes_GMWarpedToTemplate.nii.gz
	3dMean -prefix ${prefix}_AvgSubCortSegWarped.nii.gz ${base}/*/antCT/highRes_SubCortWarpedToTemplate.nii.gz
	3dMean -prefix ${prefix}_AvgBSSegWarped.nii.gz ${base}/*/antCT/highRes_BSWarpedToTemplate.nii.gz
	3dcalc -a ${prefix}_AvgBSSegWarped.nii.gz -expr 'step(a-.1)*a' -prefix ${prefix}_AvgBSSegWarped10.nii.gz
	3dcalc -a ${prefix}_AvgCerSegWarped.nii.gz -expr 'step(a-.1)*a' -prefix ${prefix}_AvgCerSegWarped10.nii.gz
	3dcalc -a ${prefix}_AvgSubCortSegWarped.nii.gz -expr 'step(a-.1)*a' -prefix ${prefix}_AvgSubCortSegWarped10.nii.gz
	3dcalc -a ${prefix}_AvgGMSegWarped.nii.gz -expr 'step(a-.1)*a' -prefix ${prefix}_AvgGMSegWarped10.nii.gz

	3dcalc -a ${prefix}_AvgGMSegWarped10.nii.gz -b ${prefix}_AvgSubCortSegWarped10.nii.gz -c ${prefix}_AvgCerSegWarped10.nii.gz -d ${prefix}_AvgBSSegWarped10.nii.gz -expr 'step(a+b+c+d)' -prefix ${prefix}_mask10.nii.gz
	3dcalc -a ${prefix}_AvgGMSegWarped10.nii.gz -b ${prefix}_AvgSubCortSegWarped10.nii.gz -c ${prefix}_AvgCerSegWarped10.nii.gz -d ${prefix}_AvgBSSegWarped10.nii.gz -e ${prefix}_mask10.nii.gz -expr 'pairmax(a,b,c,d,1,2,3,4)*e' -prefix ${prefix}_blurMask10.nii.gz
fi
###Prep for VBM
if [[ $VBM == "T" ]];then
	for i in $folders;do
		if [[ ! -f ${i}/antCT/highRes_JacModGM_blur8mm.nii.gz ]];then
			echo "cd ${i}/antCT;3dcalc -a highRes_GMWarpedToTemplate.nii.gz -b highRes_SubCortWarpedToTemplate.nii.gz -c highRes_CerWarpedToTemplate.nii.gz -d highRes_BSWarpedToTemplate.nii.gz -e ${prefix}_AvgGMSegWarped10.nii.gz -f ${prefix}_AvgSubCortSegWarped10.nii.gz -g ${prefix}_AvgCerSegWarped10.nii.gz -h ${prefix}_AvgBSSegWarped10.nii.gz -i highRes_SubjectToTemplateLogJacobian.nii.gz -expr '(a*e+b*f+c*g+d*h)*i' -prefix highRes_JacModGM.nii.gz;3dBlurInMask -input highRes_JacModGM.nii.gz -Mmask ${prefix}_blurMask10.nii.gz -FWHM 8 -prefix highRes_JacModGM_blur8mm.nii.gz" >> $prefix.VBM.swarm
		fi
	done
	swarmBiac $prefix.VBM.swarm DBIS.01 1
	lenJac=0
	while [[ $lenJac -lt $num ]];do
		sleep 10
		lenJac=$(ls ${base}/*/antCT/highRes_JacModGM.nii.gz | wc -l)
	done
fi
##Smoooth Cortical thickness if it hasn't already been done
for i in $folders;do
	if [[ ! -f ${i}/antCT/highRes_CorticalThicknessNormalizedToTemplate_blur8mm.nii.gz ]];then
		echo "cd ${i}/antCT;3dBlurInMask -input highRes_CorticalThicknessNormalizedToTemplate.nii.gz -mask ${prefix}_AvgGMSegWarped25connected.nii.gz -FWHM 8 -prefix highRes_CorticalThicknessNormalizedToTemplate_blur8mm.nii.gz" >> ${prefix}.CTblur.swarm
	fi
done
swarmBiac $prefix.CTblur.swarm DBIS.01 1

rm ${base}/*/antCT/highRes_CerWarpedToTemplate.nii.gz ${base}/*/antCT/highRes_BSWarpedToTemplate.nii.gz ${base}/*/antCT/highRes_subCortWarpedToTemplate.nii.gz ${base}/*/antCT/highRes_GMWarpedToTemplate.nii.gz ${prefix}_AvgBSSegWarped.nii.gz ${prefix}_AvgSubCortSegWarped.nii.gz ${prefix}_AvgCerSegWarped.nii.gz ${prefix}.Warp.swarm ${prefix}.CTblur.swarm ${prefix}.VBM.swarm
