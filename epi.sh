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
#7) Add in Making of Images and directions for QA (Can use ANTs command CreateTiledMosaic)
#8) Add in echos for Titles in LOG that can orient LOG reader 
###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!##########################

##Initiates variables

sub=20161103_214449 #$1 or flag -s  #pipenotes= Change away from HardCoding later
task=Rest #$2 or flag -t #pipenotes= Change away from HardCoding later
FDthresh=.7 #pipenotes= Change away from HardCoding later, also find citations for what you decide likely power 2014, minimun of .5 fd 20DVARS suggested
DVARSthresh=1.4 #pipenotes= Change away from HardCoding later, also find citations for what you decide
epi=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Func/20161103_21449/run005_04/*.hdr
copl=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_002.nii.gz
outDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449/${task}
tmpDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449/tmp
antDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/20161103_214449/antCT
template= #pipenotes= Change away from HardCoding later
antPrefix="highRes_" #pipenotes= Change away from HardCoding later

##Set up directory
mkdir -p $outDir
mkdir $tmpDir
cd $outDir

echo ""
echo "#########################################################################################################"
echo "#########################################Prep epi for warping############################################"
echo "#########################################################################################################"
echo ""
3dTcat -prefix ${tmpDir}/epi.nii.gz -tr 2 $epi #Combine each TR into one dataset
###Resample structural to voxel dimensions of epi for grid when applying warps 
3dTshift -tpattern altplus -prefix ${tmpDir}/epi_t.nii.gz ${tmpDir}/epi.nii.gz #perform t-shifting
3dvolreg -base 0 -prefix ${tmpDir}/epi_tv.nii.gz -1Dfile ${outDir}/motion.1D ${tmpDir}/epi_t.nii.gz # volume registation and extraction of motion trace
3dAutomask -prefix ${tmpDir}/epi_ExtractionMask.nii.gz ${tmpDir}/epi_tv.nii.gz #Create brain mask for extraction
3dcalc -a ${tmpDir}/epi_ExtractionMask.nii.gz -b ${tmpDir}/epi_tv.nii.gz -expr 'a*b' -prefix ${tmpDir}/epi_tvb.nii.gz #extract brain
3dTstat -prefix ${tmpDir}/epi_tvbm.nii.gz ${tmpDir}/epi_tvb.nii.gz # Create mean image for more robust alignment to sub T1
N4BiasFieldCorrection -i ${tmpDir}/epi_tvbm.nii.gz #Correct image non-uniformities in mean(not analyzed just for registration) to improve coregistration

##Handle obliquity with Extra warping but limit interpolation of EPI to one big step instead of multiple, 
#Skull strip coplanar using alignment to highRes and then use coplanar
cp $copl ${tmpDir}/copl.nii.gz
N4BiasFieldCorrection -i ${tmpDir}/copl.nii.gz
antsRegistrationSyN.sh -d 3 -m ${antDir}/${antPre}T1.nii.gz -f ${tmpDir}/copl.nii.gz -t r -n 1 -o ${tmpDir}/highres2copl
antsApplyTransforms -t ${tmpDir}/highres2copl0GenericAffine.mat -r $copl -d 3 -i ${antDir}/${antPre}BrainExtractionMask.nii.gz -o ${tmpDir}/highres2copl_BrainMask1.nii.gz
3dcalc -a ${tmpDir}/highres2copl_BrainMask1.nii.gz -expr 'step(a)' -prefix ${tmpDir}/highres2copl_BrainMask2.nii.gz
3dcalc -a ${tmpDir}/copl.nii.gz -b ${tmpDir}/highres2copl_BrainExt2.nii.gz -expr 'a*b' -prefix ${tmpDir}/copl_Brain.nii.gz

echo ""
echo "#########################################################################################################"
echo "############Calculates Warps to align epi to template via subjects Coplanar and HighRes T1###############"
echo "#########################################################################################################"
echo ""
#Calculate warps  
antsRegistrationSyN.sh -d 3 -m ${tmpDir}/epi_tvbm.nii.gz -f ${tmpDir}/copl_Brain.nii.gz -t a -n 1 -o ${outDir}/epi2copl  #Using affine registration to copl, performs slightly better and may help with distrotion
antsRegistrationSyN.sh -d 3 -m ${tmpDir}/copl_Brain.nii.gz -f ${outDir}/antCT/${antPre}Brain.nii.gz -t r -n 1 -o ${outDir}/copl2highRes # using Rigid registration to high res because they are basically the same
voxSize=$(@GetAfniRes ${tmpDir}/epi.nii.gz)
3dresample -inset $template-master ${tmpDir}/epi.nii.gz -prefix ${tmpDir}/referenceWepiSpacing.nii.gz

##Apply Warps
antsApplyTransforms -d 3 -i ${tmpDir}/epi_tvb.nii.gz -r ${tmpDir}/referenceWepiSpacing.nii.gz -t -o ${tmpDir}/epiWarped.nii.gz
echo ""
echo "#########################################################################################################"
echo "###############Get Motion and QA vals and make Aligment Montage for Visual Inspection####################"
echo "#########################################################################################################"
echo ""
######Calculation of motion, DVARs, alignment correlation and plots to have for censoring and QC
#Calculate FD, #citation: Power et al., 2012 
fsl_motion_outliers -i ${tmpDir}/epi_t.nii.gz -o ${tmpDir}/conf -s ${outDir}/FD.1D --fd #Use fsl tools because the automatically do it the same as Power 2012
#Caluclate DVARS #citation: Nichols, 2013
DVARS.sh ${tmpDir}/epi_tv.nii.gz ${outDir}/DVARS.1D  ##Use Tom Nichols standardized DVARs #pipenotes: consider rescaling to Power 2014 so you can use his threshold suggestions
#Calculate derivative of motion params for confound regression, #citation: Power et al., 2014
1d_tool.py -infile ${outDir}/motion.1D -derivative -write ${outDir}/motion_deriv.1D
#calculate TRs above threshold
awk -v thresh=$FDthresh '{if($1 > thresh) print NR}' ${outDir}/FD.1D > ${outDir}/FDcensorTRs.1D #find TRs above threshold 
awk -v thresh=$DVARSthresh '{if($1 > thresh) print NR}' ${outDir}/DVARS.1D > ${outDir}/DVARScensorTRs.1D #find TRs above threshold 
cat ${outDir}/FDcensorTRs.1D ${outDir}/DVARScensorTRs.1D | sort -g | uniq > ${outDir}/censorTRs.1D #cobine DVARS and FD TRs above threshold 
###Make QC vals file, spatial correlations for each warp, and anything else from http://ccpweb.wustl.edu/pdfs/2013hcp2_barch.pdf

##Make QC/QA montages
#pipenotes: consider making carpet plots and WC-RSFC plots for at least all connectivity pipelines before and after preprocessing

##Clean up
#rm -r $tmpDir


##########Citations
#Nichols, 2013 http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/scripts/fsl/StandardizedDVARS.pdf and https://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/scripts/fsl/DVARS.sh
#Power, J. D., Barnes, K. A., Snyder, A. Z., Schlaggar, B. L., & Petersen, S. E. (2012). Spurious but systematic correlations in functional connectivity MRI networks arise from subject motion. NeuroImage, 59(3), 2142–2154. http://doi.org/10.1016/j.neuroimage.2011.10.018



