#!/bin/bash
#
# Script: commDetection.sh
# Purpose: Takes minProc Epi data and performs Bassett style preproccesing, community detection and metric extraction
# Author: Maxwell Elliott
# Date: 06/07/17

##Wrapper around various tools to link pipeline between afni and matlab

#add in regression of task design from task time series

minProcDir=$1 ##Directory created by epi_minProc_DNS.sh
roiMask=$2 #mask with indidual value for each roi to be extracted to be a node
prefix=$3 #Will be appended to output in outDir, probably best to just have parcellation name like lausanne60
subInd=$(echo $minProcDir | sed 's_/_\n_g' | grep -n "DNS[0123]" | cut -d ":" -f1)
subDir=$(echo $minProcDir | cut -d "/" -f1-${subInd})
outDir=${minProcDir}/commDetection
task=$(echo $minProcDir | rev | cut -d "/" -f1 | rev) #grab task name for regression of task design
mkdir -p ${outDir}
tmpDir=${outDir}/tmp
mkdir -p  ${tmpDir}
templateDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500 #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI_  #pipenotes= update/Change away from HardCoding later
antDir=${subDir}/antCT
antPre="highRes_" 
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $minProcDir

voxSize=$(@GetAfniRes ${minProcDir}/epiWarped.nii.gz)
3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz

###Check if compCorr has been run and run it if not
if [[ -f ${outDir}/pc5.wm.csf_vec.1D ]];then
	echo "compCorr already run"
else
	antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors1.nii.gz
	antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors3.nii.gz
	3dcalc -a ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -b ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -expr 'step(a-0.95)+step(b-0.95)' -prefix ${tmpDir}/seg.wm.csf.nii.gz
	3dmerge -1clust_depth 5 5 -prefix ${tmpDir}/seg.wm.csf.depth.nii.gz ${tmpDir}/seg.wm.csf.nii.gz
	3dcalc -a ${tmpDir}/seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix ${tmpDir}/seg.wm.csf.erode.nii.gz ##pipenotes:for DBIS may want to edit this to move further away from WM because of smaller voxels
	3dcalc -a ${tmpDir}/seg.wm.csf.erode.nii.gz -b ${minProcDir}/epiWarped.nii.gz -expr 'a*b' -prefix ${tmpDir}/epi.wm.csf.nii.gz
	3dpc -pcsave 5 -prefix ${tmpDir}/pc5.wm.csf ${tmpDir}/epi.wm.csf.nii.gz
	mv ${tmpDir}/pc5.wm.csf_vec.1D ${outDir}/
fi

#project out nuisance variables, compCorr and task design as well as bandpass and blur
#citation) highpass of .02 comes from Bassett papers that used a 50s cutoff highpass. We are only examining wavelet 2 .06 to .12 so my understanding is that this doesn't matter much anyway
if [[ ! -s ${outDir}/${prefix}_timeSeries.1D ]];then
	if [[ $task == "faces" ]] || [[ $task == "cards" ]] || [[ $task == "facename" ]] || [[ $task == "numLS" ]];then
		3dTproject -input ${minProcDir}/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz  -prefix ${tmpDir}/tmp.epiPrepped.nii.gz -ort ${templateDir}/${task}.Decon.xmat.1D -ort ${minProcDir}/motion.1D -ort ${outDir}/pc5.wm.csf_vec.1D -polort 1 -stopband 0 0.02 -blur 8
		/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/utils/roi2ts.R -i ${tmpDir}/tmp.epiPrepped.nii.gz -r ${roiMask} > ${outDir}/${prefix}_timeSeries.1D
	elif [[ $task == "rest1" ]] || [[ $task == "rest2" ]];then
		3dTproject -input ${minProcDir}/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz  -prefix ${tmpDir}/tmp.epiPrepped.nii.gz -ort ${minProcDir}/motion.1D -ort ${outDir}/pc5.wm.csf_vec.1D -polort 1 -stopband 0 0.02 -blur 8
		/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/utils/roi2ts.R -i ${tmpDir}/tmp.epiPrepped.nii.gz -r ${roiMask} > ${outDir}/${prefix}_timeSeries.1D
	else
		echo "minProc dir must be incorrect, task name is not recognized"
		exit
	fi
fi

mkdir -p ${outDir}/matrices
if [[ ! -f  ${outDir}/matrices/${prefix}_adjMatWin3 ]];then
	matlab -nodesktop -nosplash -nojvm -r "addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/wmtsa/dwt'));addpath(genpath('${scriptsDir}')); cohAdjMat('${outDir}/${prefix}_timeSeries.1D','${outDir}/matrices/','$prefix'); exit"
else
	echo "skipping creation of matrices, already done"
fi
mkdir -p ${outDir}/metrics
if [[ ! -f ${outDir}/metrics/${prefix}_avgDisjoint ]];then
	matlab -nodesktop -nosplash -nojvm -r "addpath(genpath('/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/wmtsa/dwt'));addpath(genpath('${scriptsDir}')); detectConsensusCommunities('${outDir}/matrices/','${outDir}/metrics/','$prefix'); exit"
else
	echo "skipping community detection, already done"
fi
rm -r ${tmpDir}
