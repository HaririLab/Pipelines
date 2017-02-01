#!/bin/bash

#Process epi for future processing with task or rest pipeline

###Requires T1 pipeline to have been run


##Current Ideas

#run 3dvolreg,3dAutomask, align_centers to a sub struct that is rigidly aligned to MNI space, run align_epitoAnat.py, then apply nonlinear warp from antsCT pipeline.

sub=20161103_214449
testDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449
cd $testDir

3dTcat -prefix epiTest.nii.gz -tr 2 /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Func/20161103_21449/run005_04/*.hdr
3dTshift -tpattern altplus -prefix epiTest_t.nii.gz epiTest.nii.gz
3dvolreg -base 0 -prefix epiTest_vr.nii.gz -1Dfile motionParams.1D epiTest_t.nii.gz
3dWarp -deoblique 

########SO far seems like antsRigid registration then nonlinear between T1 and template is most tractable (deoblique first might help). look into synBOLD in ants, but seems to need to be run through ANTSr. 


align_epi_anat.py -anat ${testDir}/antCT/highRes_Brain.nii.gz -epi epiTest.nii.gz -epi_base mean -AddEdge -align_centers -epi2anat -anat_has_skull no -epi_strip 3dAutomask -volreg 3dvolreg -volreg_base 0 -tshift on -tshift_opts '-tpattern altplus'
