#!/bin/bash 

# Script: updateDBISprep.sh
# Purpose: Check for new DBIS subjects, generate swarm files and run preprocessing for anat, minProc Epi and first level EPI processing
# Author: Maxwell Elliott
# Date: 3/9/17


####For now just make swarm files for structural preprocessing and submit them....Maybe also update your covariates file from HonaLee


rawDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/SPM/Processed
outDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging

###Stuctural prepping
for sub in $(ls ${rawDir}/DMHDS[01]*/anat/HighRes.nii* | cut -d "/" -f10);do
	if [[ ! -f ${outDir}/${sub}/antCT/highRes_CorticalThicknessNormalizedToTemplate.nii.gz ]];then
		echo "mkdir -p /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/QA;/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/preprocessing/anat_DBIS.sh ${sub} 1 >> /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/QA/LOG.anat"
	fi
done
