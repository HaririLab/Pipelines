#!/bin/bash 

# Script: updateDBIStemplate.sh
# Purpose: make new template with all high quality T1 scans available, retain voxel size
# Author: Maxwell Elliott
# Date: 3/9/17

##First you have to take the DBIS.xlsx file and copy and paste first 2 columns with just DMHDS id and rating into a csvfile, then pass that file into this as the first arg

qcFile=$1

numSubs=$(sed 's/,/ /g' $qcFile | awk '$2 >= 3' | wc -l)

mkdir /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/DBIS$numSubs
outDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/DBIS$numSubs

for i in $(sed 's/,/ /g' $qcFile | awk '$2 >= 3' | cut -d " " -f1);do
	echo "antsRegistrationSyN.sh -d 3 -t r -f /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI_submmVox.nii.gz -m /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/SPM/Processed/${i}/anat/HighRes.nii -o ${outDir}/temp.rigid.$i." >> ${outDir}/swarm.initialRwarp
done

swarmBiac ${outDir}/swarm.initialRwarp DBIS.01 1

echo "cd ${outDir};buildtemplateparallel.sh -d 3 -o ${outDir}/DBIS${numSubs} -r 1 temp.rigid*.nii.gz >> ${outDir}/LOG.makeTemplate" > ${outDir}/swarm.makeTemplate

rLen=0
while [ $rLen -lt $numSubs ];do
	sleep 10
	echo "waiting 10 seconds, $rLen subs finished need $numSubs"
	rLen=$(ls ${outDir}/rigidTemp.*nii.gz | wc -l)
done
 
swarmBiac ${outDir}/swarm.makeTemplate DBIS.01 1
