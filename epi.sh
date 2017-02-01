#!/bin/bash
####epi.sh

#Process epi for future processing with task or rest pipeline
###Requires T1 pipeline to have been run


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1) make citations #citations
#2) Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later
#3) 3drefit all files in MNI space with -space MNI -view tlrc
#4) Keep all temp files in the temp space provided by BIAC
#5) Add blocks with checks to see if parts of script have been run
#6) Add a function in the scripts dir to check for dependencies and tell user how to install
#7) Add in echos for Titles in LOG that can orient LOG reader 
###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!##########################


##Current Ideas

#run 3dvolreg,3dAutomask, align_centers to a sub struct that is rigidly aligned to MNI space, run align_epitoAnat.py, then apply nonlinear warp from antsCT pipeline.

sub=20161103_214449
testDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449
cd $testDir

#########################################Prep epi for warping############################################
3dTcat -prefix epiTest.nii.gz -tr 2 /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Func/20161103_21449/run005_04/*.hdr #Combine each TR into one dataset
###Resample structural to voxel dimensions of epi for grid when deobliquing
#voxSize=$(@GetAfniRes epiTest.nii.gz)
#3dresample -inset antCT/highRes_Brain.nii.gz -master epiTest.nii.gz -prefix referenceWepiSpacing.nii.gz
3dTshift -tpattern altplus -prefix epiTest_t.nii.gz epiTest.nii.gz #perform t-shifting

3dvolreg -base 0 -prefix epiTest_tv.nii.gz -1Dfile motionParams.1D epiTest_t.nii.gz # volume registation and extraction of motion trace
3dAutomask -prefix epiTest_ExtractionMask.nii.gz epiTest_tv.nii.gz #Create brain mask for extraction
3dcalc -a epiTest_ExtractionMask.nii.gz -b epiTest_tv.nii.gz -expr 'a*b' -prefix epiTest_tvb.nii.gz #extract brain
N4BiasFieldCorrection -i epiTest_tvb.nii.gz #Correct image non-uniformities to improve coregistration
3dMean -prefix epiTest_tvbm.nii.gz epiTest_tvb.nii.gz # Create mean image for more robust alignment to sub T1


#####################Calculate warp between mean epi and subject's structural, to later be combined with warp between T1 and template#############################

##Handle obliquity with Extra warping but limit interpolation of EPI to one big step instead of multiple

antsRegistrationSyN.sh -d 3 -m antCT/highRes_deOb.rWarped.nii.gz -f /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_002.nii.gz -t r -n 12 -o highres2copl
antsApplyTransforms -t highres2copl0GenericAffine.mat -r /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_002.nii.gz -d 3 0i antCT/highRes_BrainExtractionMask.nii.gz -o copl2highres_BrainExt1.nii.gz
3dcalc -a copl2highres_BrainExt1.nii.gz -expr 'step(a)' -prefix copl2highres_BrainExt2.nii.gz
3dcalc -a bia5_21449_002.nii.gz -b copl2highres_BrainExt2.nii.gz -expr 'a*b' -prefix copl2highres_Brain.nii.gz


#pipeNotes: Think about and test making an R wrapper (ANTsR) so you can use the synBOLD functionality, could also combine with template warp and apply 
antsRegistrationSyN.sh -d 3 -m epiTest_tvbm.nii.gz -f copl2highres_Brain.nii.gz -t r -n 1 -o epi2copl
antsRegistrationSyN.sh -d 3 -m copl2highres_Brain.nii.gz -f antCT/highRes_Brain.nii.gz -t r -n 1 -o copl2highRes


