#!/bin/bash 

# Script: updateDBISprep.sh
# Purpose: Check for new DBIS subjects, generate swarm files and run preprocessing for anat, minProc Epi and first level EPI processing
# Author: Maxwell Elliott
# Date: 3/9/17


####For now just make swarm files for structural preprocessing and submit them....Maybe also update your covariates file from HonaLee


rawDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Data/OTAGO
outDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging

###Stuctural prepping
for sub in $(ls -d ${rawDir}/DMHDS[01]*/DMHDS/MR_t1_0.9_mprage_sag_iso_p2 | cut -d "/" -f9);do
	if [[ ! -f ${outDir}/FreeSurfer/${sub}/SUMA/std.60.rh.thickness.niml.dset ]];then
		echo "mkdir -p /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/QA;/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/preprocessing/anat_DBIS.sh ${sub} 1 >> /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/QA/LOG.anat"
	fi
done
