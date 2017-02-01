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
#6) 
#7) Add in echos for Titles in LOG that can orient LOG reader 
###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!##########################


##Current Ideas

#run 3dvolreg,3dAutomask, align_centers to a sub struct that is rigidly aligned to MNI space, run align_epitoAnat.py, then apply nonlinear warp from antsCT pipeline.

sub=20161103_214449
testDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449
cd $testDir

###Resample structural to voxel dimensions of epi for grid when deobliquing
voxSize=$(@GetAfniRes epiTest.nii.gz)
3dresample -inset antCT/highRes_Brain.nii.gz -master epiTest.nii.gz -prefix referenceWepiSpacing.nii.gz
#Prep epi for warping
3dTcat -prefix epiTest.nii.gz -tr 2 /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Func/20161103_21449/run005_04/*.hdr #Combine each TR into one dataset
3dTshift -tpattern altplus -prefix epiTest_t.nii.gz epiTest.nii.gz #perform t-shifting
3dWarp -deoblique -gridset refAnatEpiSpace.nii.gz -prefix epiTest_td.nii.gz epiTest_t.nii.gz #deoblique dataset to avoid alignment and grid issues when warping to T1 and template
3dvolreg -base 0 -prefix epiTest_tdv.nii.gz -1Dfile motionParams.1D epiTest_td.nii.gz # volume registation and extraction of motion trace
3dAutomask -prefix epiTest_ExtractionMask.nii.gz epiTest_tdv.nii.gz #Create brain mask for extraction
3dcalc -a epiTest_ExtractionMask.nii.gz -b epiTest_tdv.nii.gz -expr 'a*b' -prefix epiTest_tdvb.nii.gz #extract brain
N4BiasFieldCorrection -i epiTest_tdvb.nii.gz #Correct image non-uniformities to improve coregistration
3dMean -prefix epiTest_tdvbm.nii.gz epiTest_tdvb.nii.gz # Create mean image for more robust alignment to sub T1


####Calculate warp between mean epi and subject's structural, to later be combined with warp between T1 and template

#pipeNotes: Think about and test making an R wrapper (ANTsR) so you can use the synBOLD functionality, could also combine with template warp and apply 
antsRegistrationSyN.sh -d 3 -m epiTest_tdvbMean.nii.gz -f antCT/highRes_Brain.nii.gz -t r -n 1 -o epi2anat
########SO far seems like antsRigid registration then nonlinear between T1 and template is most tractable (deoblique first might help). look into synBOLD in ants, but seems to need to be run through ANTSr. 


#align_epi_anat.py -anat ${testDir}/antCT/highRes_Brain.nii.gz -epi epiTest.nii.gz -epi_base mean -AddEdge -align_centers -epi2anat -anat_has_skull no -epi_strip 3dAutomask -volreg 3dvolreg -volreg_base 0 -tshift on -tshift_opts '-tpattern altplus'
