#!/bin/bash
#
# Script: rest_DNS.sh
# Purpose: Take a minimally preprocessed Resting State Scan and finish preprocessing so that subject is ready for Group Analyses
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
minProcEpi1=${outDir}/rest1/epiWarped.nii.gz
minProcEpi2=${outDir}/rest2/epiWarped.nii.gz
templateDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT #pipenotes= update/Change away from HardCoding later
templatePre=dunedin98Template_MNI_ #pipenotes= update/Change away from HardCoding later
antDir=${subDir}/antCT
antPre="highRes_" #pipenotes= Change away from HardCoding later
FDthresh=.25 #pipenotes= Change away from HardCoding later, also find citations for what you decide likely power 2014, minimun of .5 fd 20DVARS suggested
DVARSthresh=1.5 #pipenotes= Change away from HardCoding later, also find citations for what you decide

mkdir -p $tmpDir
##Nest minProc within overarching rest directory
mv ${subDir}/rest[12] ${outDir}/
if [[ ! -f ${minProcEpi1} ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!No minimally processed Rest Scan Found!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!need to run epi_minProc_DNS.sh first before this script!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi
###Figure out if you should process 2 run or 1
if [[ -f ${minProcEpi2} ]];then
	numRest=2
else
	numRest=1
fi

###Extract CompCor Components
voxSize=$(@GetAfniRes ${minProcEpi1})
numTR=$(3dinfo -nv ${minProcEpi1})
numTR2=$(3dinfo -nv ${minProcEpi2})
##Check to make sure rest scans are the same size
if [[ $numTR != $numTR2 ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!Rest scans are of different size!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!Check minProc Pipeline to make sure things add up!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi
3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors1.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors3.nii.gz
3dcalc -a ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -b ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -expr 'step(a-0.95)+step(b-0.95)' -prefix ${tmpDir}/seg.wm.csf.nii.gz
3dmerge -1clust_depth 5 5 -prefix ${tmpDir}/seg.wm.csf.depth.nii.gz ${tmpDir}/seg.wm.csf.nii.gz
3dcalc -a ${tmpDir}/seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix ${tmpDir}/seg.wm.csf.erode.nii.gz ##pipenotes:for DBIS may want to edit this to move further away from WM because of smaller voxels

for restNum in $(seq 1 $numRest);do
	3dcalc -a ${tmpDir}/seg.wm.csf.erode.nii.gz -b ${outDir}/rest${restNum}/epiWarped.nii.gz -expr 'a*b' -prefix ${tmpDir}/rest${restNum}.wm.csf.nii.gz
	3dpc -pcsave 5 -prefix ${tmpDir}/pcRest${restNum}.wm.csf ${tmpDir}/rest${restNum}.wm.csf.nii.gz
	mv ${tmpDir}/pcRest${restNum}.wm.csf_vec.1D ${outDir}/
	####Setup Censoring
	cenTRdelta=$(echo "($restNum - 1)*${numTR}" | bc)
	awk -v thresh=$FDthresh '{if($1 > thresh) print NR}' ${outDir}/rest${restNum}/FD.1D | awk '{print ($1 - 1) " " $2}' > ${tmpDir}/raw${restNum}FDcensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
	awk -v thresh=$DVARSthresh '{if($1 > thresh) print NR}' ${outDir}/rest${restNum}/DVARS.1D | awk '{print ($1 - 1) " " $2}' > ${tmpDir}/raw${restNum}DVARScensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
	1deval -a ${tmpDir}/raw${restNum}FDcensorTRs.1D -expr "a+$cenTRdelta" > ${outDir}/FDcensorTRs${restNum}.1D
	1deval -a ${tmpDir}/raw${restNum}DVARScensorTRs.1D -expr "a+$cenTRdelta" > ${outDir}/DVARScensorTRs${restNum}.1D
done


cat ${outDir}/FDcensorTRs*.1D ${outDir}/DVARScensorTRs*.1D | sort -g | uniq > ${outDir}/censorTRs.1D #combine DVARS and FD TRs above threshold 
cat ${outDir}/rest*/motion.1D > ${outDir}/allmotion.1D
cat ${outDir}/rest*/motion_deriv.1D > ${outDir}/allmotion_deriv.1D
cat ${outDir}/pcRest*.wm.csf_vec.1D > ${outDir}/allCompCorr.1D

####Project everything out
clist=$(cat ${outDir}/censorTRs.1D)
lenC=$(echo $clist | wc -w )
if [[ $lenC == 0 ]];then
	3dTproject -input ${outDir}/rest*/epiWarped.nii.gz -prefix ${outDir}/epiPrepped.nii.gz -ort ${outDir}/allmotion.1D -ort ${outDir}/allmotion_deriv.1D -ort ${outDir}/allCompCorr.1D -polort 1 -bandpass 0.008 0.10 -blur 6 ##pipeNotes: add in mask based on subjects GM warped to template and thresholded and make sure epis are read in in the correct order
else
	3dTproject -input ${outDir}/rest*/epiWarped.nii.gz -prefix ${outDir}/epiPrepped.nii.gz -CENSORTR $clist -ort ${outDir}/allmotion.1D -ort ${outDir}/allmotion_deriv.1D -ort ${outDir}/allCompCorr.1D -polort 1 -bandpass 0.008 0.10 -blur 6 ##pipeNotes: add in mask based on subjects GM warped to template and thresholded and make sure epis are read in in the correct order
fi


#pipenotes: Cen options in 3dTproject start at 0, currently ours based on awk start with 1. Make sure to subtract 1 before giving to tproject!!!!

