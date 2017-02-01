#!/bin/bash

####anat.sh

#Beginings of pipeline for processing anatomical images
##Preps anat for anat analyses and fMRI


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1)make citations #citations
#2)Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later
#3) 3drefit all files in MNI space with -space MNI -view tlrc
###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!###########################


###set sub for testing purposes, these should be input variable or internal variables in the real pipeline
sub=20161103_214449
testDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449

#### Local variables
SUBJECTS_DIR=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449

cd $testDir

##Deoblique dataset, not sure how big of deal this is but it gets rid of AFNI warnings and complaints at least
3dWarp -prefix highRes_deOb.nii.gz -gridset /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_006.nii.gz -deoblique /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_006.nii.gz
###Rigidly align 
antsRegistrationSyN.sh -d 3 -t r -f /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98Template_MNI.nii.gz -m highRes_deOb.nii.gz -o highRes_deOb.r

brainExtractSYN.sh /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI.nii.gz /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI_BrainExtractionMask.nii.gz highRes

###Run antCT
mkdir antCT
antsCorticalThickness.sh -d 3 -a highRes_deOb.rWarped.nii.gz -e /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI.nii.gz -m /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI_BrainCerebellumProbabilityMask.nii.gz -p /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI_BrainSegmentationPosteriors%d.nii.gz -t /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/templates/dunedin98_antCT/dunedin98Template_MNI_Brain.nii.gz -o highRes_


###Prep for Freesurfer with PreSkull Stripped
#Citation: followed directions from https://surfer.nmr.mgh.harvard.edu/fswiki/UserContributions/FAQ (search skull)

mksubjdirs FreeSurf_$sub
mri_convert highRes_Brain.nii.gz FreeSurf_20161103_214449/mri/001.mgz
#Run 
recon-all -all -noskullstrip -s FreeSurf_20161103_214449
cp FreeSurf_${sub}/T1.mgz FreeSurf_${sub}/brainmask.auto.mgz
cp FreeSurf_${sub}/brainmask.auto.mgz FreeSurf_${sub}/brainmask.mgz
recon-all -autorecon2 -autorecon3 -s FreeSurf_20161103_214449 
#Run SUMA
@SUMA_Make_Spec_FS -ld 60 -sid FreeSurf_${sub}

#cleanup
mv highRes_* antCT/

