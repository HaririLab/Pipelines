#!/bin/bash
#
# Script: rest_DNS.sh
# Purpose: Take a minimally preprocessed Resting State Scan and finish preprocessing up to Group Analyses
# Author: Maxwell Elliott

################Steps to include#######################
#1)despike
#2)motion Regress 12 params
#3)censor
#4) bandpass
#5) compcorr
#6) 

###Eventually
#surface
#graph Analysis construction


###############################################################################
#
# Environment set up
#
###############################################################################
sub=$1
subDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/${sub}
outDir=${subDir}/rest
tmpDir=${outDir}/tmp
minProcEpi=${outDir}/epiWarped.nii.gz
templateDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT #pipenotes= update/Change away from HardCoding later
templatePre=dunedin98Template_MNI_ #pipenotes= update/Change away from HardCoding later
antDir=${subDir}/antCT
antPre="highRes_" #pipenotes= Change away from HardCoding later
FDthresh=.7 #pipenotes= Change away from HardCoding later, also find citations for what you decide likely power 2014, minimun of .5 fd 20DVARS suggested
DVARSthresh=1.4 #pipenotes= Change away from HardCoding later, also find citations for what you decide

mkdir -p $tmpDir
if [[ ! -f ${minProcEpi} ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!No minimally processed Rest Scan Found!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!need to run epi_minProc_DNS.sh first before this script!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi

###Extract CompCor Components
voxSize=$(@GetAfniRes ${minProcEpi})
3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors1.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors3.nii.gz
3dcalc -a ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -b ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -expr 'step(a-0.95)+step(b-0.95)' -prefix ${tmpDir}/seg.wm.csf.nii.gz
3dmerge -1clust_depth 5 5 -prefix ${tmpDir}/seg.wm.csf.depth.nii.gz ${tmpDir}/seg.wm.csf.nii.gz
3dcalc -a ${tmpDir}/seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix ${tmpDir}/seg.wm.csf.erode.nii.gz ##pipenotes:for DBIS may want to edit this to move further away from WM because of smaller voxels
3dcalc -a ${tmpDir}/seg.wm.csf.erode.nii.gz -b ${outDir}/epiWarped.nii.gz -expr 'a*b' -prefix ${tmpDir}/rest.wm.csf.nii.gz
3dpc -pcsave 5 -prefix ${tmpDir}/pc.wm.csf ${tmpDir}/rest.wm.csf.nii.gz
mv ${tmpDir}/pc.wm.csf_vec.1D ${outDir}/

###Censoring Stats and Processing
awk -v thresh=$FDthresh '{if($1 > thresh) print NR}' ${outDir}/FD.1D | awk '{print ($1 - 1) " " $2}' > ${outDir}/FDcensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
awk -v thresh=$DVARSthresh '{if($1 > thresh) print NR}' ${outDir}/DVARS.1D | awk '{print ($1 - 1) " " $2}' > ${outDir}/DVARScensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
numCenFD=$(cat ${outDir}/FDcensorTRs.1D | wc -l)
numCenDVARS=$(cat ${outDir}/DVARScensorTRs.1D | wc -l)
FDcenPer=$(echo "${numCenFD}/${nVols}" | bc -l | cut -c1-5)
DVARScenPer=$(echo "${numCenDVARS}/${nVols}" | bc -l | cut -c1-5)
cat ${outDir}/FDcensorTRs.1D ${outDir}/DVARScensorTRs.1D | sort -g | uniq > ${outDir}/censorTRs.1D #combine DVARS and FD TRs above threshold 


####Project everything out
clist=$(cat ${outDir}/censorTRs.1D)
3dTproject -input ${outDir}/epiWarped.nii.gz -prefix epiPrepped.nii.gz -CENSORTR $clist -ort ${outDir}/pc.wm.csf_vec.1D -ort motion.1D -ort motion_deriv.1D -polort 1 -bandpass 0.008 0.10 -blur 8 ##pipeNotes: add in mask based on subjects GM warped to template and thresholded




#pipenotes: Cen options in 3dTproject start at 0, currently ours based on awk start with 1. Make sure to subtract 1 before giving to tproject!!!!

