#!/bin/bash
#
# Script: epi_minProc_DNS.sh
# Purpose: Minimal preprocessing of epi for DNS study
# Author: Maxwell Elliott

#Process epi for future processing with task or rest pipeline
###Requires T1 pipeline to have been run


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1) make citations #citations
#2) Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later
#3) Handle LOG in more organized way
###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!##########################

###############################################################################
#
# Environment set up
#
###############################################################################

sub=$1 #20161103_214449 #$1 or flag -s  #pipenotes= Change away from HardCoding later
task=$2 #$2 or flag -t #pipenotes= Change away from HardCoding later
subDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/pipeTest/${sub}/ #pipenotes= Change away from HardCoding later
outDir=${subDir}/${task}
tmpDir=${outDir}/tmp
QADir=${subDir}/QA
antDir=${subDir}/antCT
antPre="highRes_" #pipenotes= Change away from HardCoding later
templateDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500 #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI_ #pipenotes= update/Change away from HardCoding later
threads=1 #default in case thread arg is not passed
threads=$3

###Check to make sure anat processing has been completed
if [[ ! -f ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!NO antsCT directory!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!need to run anat_DNS.sh first before this script!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi
###Check if this subject and task have already been processed
if [[ -f ${outDir}/epiWarped.nii.gz ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!jects $task data is already processed!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!delete $outDir and rerun this script if you want to reprocess!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi


###############################################################################
#
# Main 
#
###############################################################################

##Grab Epi and set up directories

if [[ $task == "faces" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f8)
	expLen=196
elif [[ $task == "cards" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f9)
	expLen=172
elif [[ $task == "numLS" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f10)
	expLen=354
elif [[ $task == "facename" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f11)
	expLen=162
elif [[ $task == "rest1" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f6)
	rest2Pre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f7)
	expLen=128	
elif [[ $task == "rest2" ]];then
	EpiPre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f7)
	expLen=128		
else
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EPI task Name does not match faces, cards, numLS or facename!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		exit
fi
if [[ $EpiPre == "not_collected" ]];then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!NO T1, skipping Anat Processing and Epi processing will also be unavailable!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	exit
fi
epi=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/${EpiPre}
export PATH=$PATH:/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/scripts/ #add dependent scripts to path #pipenotes= update/Change to DNS scripts
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
export OMP_NUM_THREADS=$threads
##Set up directory
mkdir -p $QADir
mkdir -p $outDir
mkdir $tmpDir
cd $outDir
####Put together TRs into full dataset and leave off last TR of cards and faces per Annchen's request
if [[ $task == "faces" ]];then
	3dTcat -prefix ${tmpDir}/epi.nii.gz -tpattern altplus -relabel -tr 2 ${epi}/V00*.hdr ${epi}/*V01[012345678]*.hdr ${epi}/V019[012345].hdr
elif [[ $task == "cards" ]];then
	3dTcat -prefix ${tmpDir}/epi.nii.gz -tpattern altplus -relabel -tr 2 ${epi}/V00*.hdr ${epi}/*V01[0123456]*.hdr ${epi}/V017[01].hdr
else
	3dTcat -prefix ${tmpDir}/epi.nii.gz -tpattern altplus -relabel -tr 2 ${epi}/V*.hdr #Combine each TR into one dataset
fi

expLen2=$(echo "$expLen-1" | bc)
###Check to make sure T1 has correct number of slices other exit and complain
lenEpi=$(ls ${epi}/*.hdr | wc -l)
if [[ $lenEpi == $expLen || $lenEpi == $expLen2 ]];then
	echo "Epi matches the assumed length"
else
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!T1 is the Wrong Size, wrong number of slices!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	exit
fi

echo ""
echo "#########################################################################################################"
echo "#########################################Prep epi for warping############################################"
echo "#########################################################################################################"
echo ""

###Resample structural to voxel dimensions of epi for grid when applying warps
3dDespike -prefix ${tmpDir}/epi_d.nii.gz ${tmpDir}/epi.nii.gz #citation:Jo et al., 2014 #pipeNotes: do we want to do this on tasks?? #citation: Kalcher et al., 2013. Example of despiking in task analysis...at least some people do this... #citation: also https://afni.nimh.nih.gov/afni/community/board/read.php?1,141185,143682#msg-143682, small comment "helpful, more important in rest than task" 
3dTshift -tpattern altplus -prefix ${tmpDir}/epi_dt.nii.gz ${tmpDir}/epi_d.nii.gz #perform t-shifting
##Pipenotes: Should you apply the rigid warp field from rest1 to rest2 data instead of re-rigid warping??
if [[ $task == "rest2" ]];then
	3dvolreg -base ${subDir}/rest1/restVolRegBase.nii.gz -prefix ${tmpDir}/epi_dtv.nii.gz -1Dfile ${outDir}/motion.1D ${tmpDir}/epi_dt.nii.gz # volume registation and extraction of motion trace with Same base as rest1
else
	3dvolreg -base 0 -prefix ${tmpDir}/epi_dtv.nii.gz -1Dfile ${outDir}/motion.1D ${tmpDir}/epi_dt.nii.gz # volume registation and extraction of motion trace
fi

3dAutomask -prefix ${tmpDir}/epi_ExtractionMask.nii.gz ${tmpDir}/epi_dtv.nii.gz #Create brain mask for extraction
3dcalc -a ${tmpDir}/epi_ExtractionMask.nii.gz -b ${tmpDir}/epi_dtv.nii.gz -expr 'a*b' -prefix ${tmpDir}/epi_dtvb.nii.gz #extract brain
3dTstat -prefix ${tmpDir}/epi_dtvbm.nii.gz ${tmpDir}/epi_dtvb.nii.gz # Create mean image for more robust alignment to sub T1
N4BiasFieldCorrection -i ${tmpDir}/epi_dtvbm.nii.gz #Correct image non-uniformities in mean(not analyzed just for registration) to improve coregistration
N4BiasFieldCorrection -i ${antDir}/${antPre}ExtractedBrain0N4.nii.gz

echo ""
echo "#########################################################################################################"
echo "###################Calculates Warps to align epi to template via subjects HighRes T1#####################"
echo "#########################################################################################################"
echo ""
###Only calculate for rest1 then apply to rest2 as they are volreged to same base
if [[ $task != "rest2" ]];then
	antsRegistrationSyN.sh -d 3 -m ${tmpDir}/epi_dtvbm.nii.gz -f ${antDir}/${antPre}ExtractedBrain0N4.nii.gz -t r -n $threads -o ${outDir}/epi2highRes #Might want to keep for Surface Processing Purposes
fi
###If this is rest1  and there is a rest2 save the base for volReg for rest2
if [[ $task == "rest1" && $restPre2 != "not_collected" ]];then
	3dcalc -a ${tmpDir}/epi_dt.nii.gz'[0]' -expr 'a' -prefix ${outDir}/restVolRegBase.nii.gz
	#####set up and submit a job to Process rest2 no that we have a volReg template from rest1
	echo "/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/epi_minProc_DNS.sh $sub rest2 $threads >> ${subDir}/QA/LOG.rest2" >> ${outDir}/swarm.rest2
	echo ""
	echo "#########################################################################################################"
	echo "#################################Submiting Job For rest2#################################################"
	echo "#########################################################################################################"
	echo ""
	swarmBiac ${outDir}/swarm.rest2 DNS.01 $threads
fi
voxSize=$(@GetAfniRes ${tmpDir}/epi.nii.gz)
3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz

##Apply Warps #citation: https://github.com/stnava/ANTs/wiki/antsCorticalThickness-and-antsLongitudinalCorticalThickness-output and https://github.com/maxwe128/restTools/blob/master/preprocessing/norm.func.spm12sa.csh 
##Used WarpTimeSeries instead of AntsApplyTransforms because it worked with 4d time series and I couldn't get applyTransforms to. But when applying each method to the mean image gave perfectly identical results
###If task is rest 2 then you want to apply the rigid epi to high rest transform from rest1 so that they are exactly the same
if [[ $task != "rest2" ]];then
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvbm.nii.gz ${tmpDir}/epiWarpedMean.nii.gz -R ${tmpDir}/refTemplate4epi.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat ${outDir}/epi2highRes0GenericAffine.mat
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvb.nii.gz ${outDir}/epiWarped.nii.gz -R ${tmpDir}/refTemplate4epi.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat ${outDir}/epi2highRes0GenericAffine.mat --use-NN #pipeNotes: eventually remove this or linear interpolation from above
	3drefit -space MNI -view tlrc ${outDir}/epiWarped.nii.gz #Refit space of warped epi so that it can be viewed in MNI space within AFNI
else
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvbm.nii.gz ${tmpDir}/epiWarpedMean.nii.gz -R ${tmpDir}/refTemplate4epi.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat $${subDir}/rest1/epi2highRes0GenericAffine.mat
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvb.nii.gz ${outDir}/epiWarped.nii.gz -R ${tmpDir}/refTemplate4epi.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat ${subDir}/rest1/epi2highRes0GenericAffine.mat --use-NN #pipeNotes: eventually remove this or linear interpolation from above
	3drefit -space MNI -view tlrc ${outDir}/epiWarped.nii.gz #Refit space of warped epi so that it can be viewed in MNI space within AFNI
fi
#####Smooth Data 6mm will get output to about 11-13 FWHM on average
3dBlurInMask -input ${outDir}/epiWarped.nii.gz -Mmask ${templateDir}/DNS500_first50_BlurMask10_EpiVox.nii.gz -FWHM 6 -prefix ${outDir}/epiWarped_blur6mm.nii.gz

echo ""
echo "#########################################################################################################"
echo "###############Get Motion and QA vals and make Aligment Montage for Visual Inspection####################"
echo "#########################################################################################################"
echo ""
######Calculation of motion, DVARs, alignment correlation and plots to have for censoring and QC
#Calculate FD, #citation: Power et al., 2012 
fsl_motion_outliers -i ${tmpDir}/epi_dt.nii.gz -o ${tmpDir}/conf -s ${outDir}/FD.1D --fd #Use fsl tools because the automatically do it the same as Power 2012 #citation: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLMotionOutliers
fsl_motion_outliers --nomoco --dvars -m ${tmpDir}/epi_ExtractionMask.nii.gz -o ${tmpDir}/tempConf -s fslDVARS.1D -i tmp/epi_dtvb.nii.gz #calc FSL style for the purpose of comparison #pipenotes: might want to remove
#Caluclate DVARS #citation: Nichols, 2013
DVARS.sh ${tmpDir}/epi_dtv.nii.gz ${outDir}/DVARS.1D  ##Use Tom Nichols standardized DVARs #pipenotes: here is one paper with a standardized DVARs threshold(1.8) #citation: https://pdfs.semanticscholar.org/8b64/7293808a4903e877f93d8241428b7596a909.pdf
#Calculate derivative of motion params for confound regression, #citation: Power et al., 2014
1d_tool.py -infile ${outDir}/motion.1D -derivative -write ${outDir}/motion_deriv.1D
#calculate TRs above threshold
awk -v thresh=".25" '{if($1 > thresh) print NR}' ${outDir}/FD.1D > ${outDir}/FD.25TRs.1D #find TRs above threshold 
awk -v thresh=".5" '{if($1 > thresh) print NR}' ${outDir}/FD.1D > ${outDir}/FD.5TRs.1D #find TRs above threshold 
###Make QC vals file, spatial correlations for each warp, and anything else from http://ccpweb.wustl.edu/pdfs/2013hcp2_barch.pdf

##Make QC/QA montages
#pipenotes: consider making carpet plots and WC-RSFC plots for at least all connectivity pipelines before and after preprocessing
3dresample -input ${templateDir}/${templatePre}BrainExtractionMask.nii.gz -master ${tmpDir}/refTemplate4epi.nii.gz -prefix ${tmpDir}/refTemplateBrainMask.nii.gz
#tSNR
3dTstat -cvarinvNOD -prefix ${tmpDir}/tSNR.nii.gz ${tmpDir}/epi_dtvb.nii.gz #mean/temporal sd,  #citation: same as Marcus et al., 2013 tSNR
tSNR=$(3dBrickStat -mask ${tmpDir}/epi_ExtractionMask.nii.gz ${tmpDir}/tSNR.nii.gz | sed "s/ *//g" | sed "s/\t\t*//g" )
#smoothness before and after warping
rawFWHM=$(3dFWHMx -mask ${tmpDir}/epi_ExtractionMask.nii.gz -combine ${tmpDir}/epi_dtvb.nii.gz | cut -d " " -f11 | sed "s/ *//g" | sed "s/\t\t*//g" )
warpedFWHM=$(3dFWHMx -mask ${tmpDir}/refTemplateBrainMask.nii.gz -combine ${outDir}/epiWarped.nii.gz | cut -d " " -f11 | sed "s/ *//g" | sed "s/\t\t*//g" )
#Motion QC Measures
nVols=$(3dinfo -nv ${outDir}/epiWarped.nii.gz)
FDavg=$(1d_tool.py -show_mmms -infile ${outDir}/FD.1D | sed 's/ /,/g' | cut -d "," -f15 | sed '/^$/d')
FDsd=$(1d_tool.py -show_mmms -infile ${outDir}/FD.1D | sed 's/ /,/g' | cut -d "," -f25 | sed '/^$/d')
DVARSavg=$(1d_tool.py -show_mmms -infile ${outDir}/DVARS.1D | sed 's/ /,/g' | cut -d "," -f15 | sed '/^$/d')
DVARSsd=$(1d_tool.py -show_mmms -infile ${outDir}/DVARS.1D | sed 's/ /,/g' | cut -d "," -f25 | sed '/^$/d')
numCenFD25=$(cat ${outDir}/FD.25TRs.1D | wc -l)
numCenFD50=$(cat ${outDir}/FD.5TRs.1D | wc -l)
FD25Per=$(echo "${numCenFD25}/${nVols}" | bc -l | cut -c1-5)
FD50Per=$(echo "${numCenFD50}/${nVols}" | bc -l | cut -c1-5)
#spatial correlations between epi and highres, epi and Template, and highRes and template as a crude index of alignment quality
antsApplyTransforms -d 3 -i ${antDir}/${antPre}ExtractedBrain0N4.nii.gz -o ${tmpDir}/BrainNormalizedToTemplate.nii.gz -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -r ${antDir}/${antPre}ExtractedBrain0N4.nii.gz
epi2TemplateCor=$(3ddot -mask ${tmpDir}/refTemplateBrainMask.nii.gz ${tmpDir}/refTemplate4epi.nii.gz ${tmpDir}/epiWarpedMean.nii.gz | sed "s/ *//g" | sed "s/\t\t*//g" )
epi2highResCor=$(3ddot -mask ${antDir}/${antPre}BrainExtractionMask.nii.gz ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${outDir}/epi2highResWarped.nii.gz | sed "s/ *//g"| sed "s/\t\t*//g")
highRes2TemplateCor=$(3ddot -mask ${templateDir}/${templatePre}BrainExtractionMask.nii.gz  ${tmpDir}/BrainNormalizedToTemplate.nii.gz ${templateDir}/${templatePre}Brain.nii.gz | sed "s/ *//g" | sed "s/\t\t*//g")
#set up QC table for subject
echo "tSNR,rawFWHM,warpedFWHM,FDavg,FDsd,DVARSavg,DVARSsd,FD25Per,FD50Per,epi2TemplateCor,epi2highResCor,highRes2TemplateCor" > ${QADir}/${task}.QCmeasures.txt
echo "$tSNR,$rawFWHM,$warpedFWHM,$FDavg,$FDsd,$DVARSavg,$DVARSsd,$FD25Per,$FD50Per,$epi2TemplateCor,$epi2highResCor,$highRes2TemplateCor" >> ${QADir}/${task}.QCmeasures.txt
######Make Edges and montage of warped edges overlain target Struct to check alignment
##epi Alignment to HighRes
3dedge3 -input ${outDir}/epi2highResWarped.nii.gz -prefix ${tmpDir}/epi2highResWarpedEdges.nii.gz  #Detect edges
ConvertScalarImageToRGB 3 ${tmpDir}/epi2highResWarpedEdges.nii.gz ${tmpDir}/epi2highResEdgesRBG.nii.gz none red none 0 10 #convert for Ants Montage
3dcalc -a ${tmpDir}/epi2highResEdgesRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/epi2highResEdgesRBGstep.nii.gz #Make mask to make Edges stand out
CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/epi2highResEdgesRBG.nii.gz -o ${QADir}/${task}.epi2HighResAlignmentCheck.png -a 0.8 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/epi2highResEdgesRBGstep.nii.gz -f 0x1  #Create Montage taking images in axial slices every 5 slices
##HighRes Alignment to Template
3dedge3 -input ${tmpDir}/BrainNormalizedToTemplate.nii.gz -prefix ${tmpDir}/highRes2TemplateWarpedEdges.nii.gz  #Detect edges
ConvertScalarImageToRGB 3 ${tmpDir}/highRes2TemplateWarpedEdges.nii.gz ${tmpDir}/highRes2TemplateEdgesRBG.nii.gz none red none 0 10 #convert for Ants Montage
3dcalc -a ${tmpDir}/highRes2TemplateEdgesRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/highRes2TemplateEdgesRBGstep.nii.gz #Make mask to make Edges stand out
CreateTiledMosaic -i ${templateDir}/${templatePre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/highRes2TemplateEdgesRBG.nii.gz -o ${QADir}/${task}.highRes2TemplateAlignmentCheck.png -a 0.8 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/highRes2TemplateEdgesRBGstep.nii.gz -f 0x1  #Create Montage taking images in axial slices every 5 slices
##epiWarpedMean to Template
if [[ $task != "rest2" ]];then
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvbm.nii.gz ${tmpDir}/epiWarpedMeanTempRef.nii.gz -R ${templateDir}/${templatePre}BrainSegmentation0N4.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat ${outDir}/epi2highRes0GenericAffine.mat #Get overlay on the same grid
else
	WarpTimeSeriesImageMultiTransform 4 ${tmpDir}/epi_dtvbm.nii.gz ${tmpDir}/epiWarpedMeanTempRef.nii.gz -R ${templateDir}/${templatePre}BrainSegmentation0N4.nii.gz ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat ${subDir}/rest1/epi2highRes0GenericAffine.mat #Get overlay on the same grid
fi
3dedge3 -input ${tmpDir}/epiWarpedMeanTempRef.nii.gz -prefix ${tmpDir}/epi2TemplateWarpedEdges.nii.gz  #Detect edges
ConvertScalarImageToRGB 3 ${tmpDir}/epi2TemplateWarpedEdges.nii.gz ${tmpDir}/epi2TemplateEdgesRBG.nii.gz none red none 0 10 #convert for Ants Montage
3dcalc -a ${tmpDir}/epi2TemplateEdgesRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/epi2TemplateEdgesRBGstep.nii.gz #Make mask to make Edges stand out
CreateTiledMosaic -i ${templateDir}/${templatePre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/epi2TemplateEdgesRBG.nii.gz -o ${QADir}/${task}.epi2TemplateAlignmentCheck.png -a 0.8 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/epi2TemplateEdgesRBGstep.nii.gz -f 0x1  #Create Montage taking images in axial slices every 5 slices
##epi edges on epi to see how edge detection worked
3dedge3 -input ${tmpDir}/epi_dtvbm.nii.gz -prefix ${tmpDir}/epiMeanEdges.nii.gz  #Detect edges
ConvertScalarImageToRGB 3 ${tmpDir}/epiMeanEdges.nii.gz ${tmpDir}/epiMeanEdgesRBG.nii.gz none red none 0 10 #convert for Ants Montage
3dcalc -a ${tmpDir}/epiMeanEdgesRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/epiMeanEdgesRBGstep.nii.gz #Make mask to make Edges stand out
CreateTiledMosaic -i ${tmpDir}/epi_dtvbm.nii.gz -r ${tmpDir}/epiMeanEdgesRBG.nii.gz -o ${QADir}/${task}.epiMeanEdgesAlignmentCheck.png -a 0.8 -t -1x-1 -d 2 -p mask -s [1,mask,mask] -x ${tmpDir}/epiMeanEdgesRBGstep.nii.gz -f 0x0  #Create Montage taking images in axial slices every 5 slices

##Clean up
#rm -r $tmpDir


##########Citations
#Jo, H. J., Gotts, S. J., Reynolds, R. C., Bandettini, P. A., Martin, A., Cox, R. W., & Saad, Z. S. (2013). Effective preprocessing procedures virtually eliminate distance-dependent motion artifacts in resting state FMRI. Journal of Applied Mathematics, 2013. http://doi.org/10.1155/2013/935154
#Kalcher, K., Boubela, R. N., Huf, W., Biswal, B. B., Baldinger, P., Sailer, U., … Windischberger, C. (2013). RESCALE: Voxel-specific task-fMRI scaling using resting state fluctuation amplitude. NeuroImage, 70, 80–88. http://doi.org/10.1016/j.neuroimage.2012.12.019
#Marcus, D. S., Harms, M. P., Snyder, A. Z., Jenkinson, M., Wilson, J. A., Glasser, M. F., … Van Essen, D. C. (2013). Human Connectome Project informatics: Quality control, database services, and data visualization. NeuroImage, 80, 202–219. http://doi.org/10.1016/j.neuroimage.2013.05.077
#Nichols, 2013 http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/scripts/fsl/StandardizedDVARS.pdf and https://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/scripts/fsl/DVARS.sh
#Power, J. D., Barnes, K. A., Snyder, A. Z., Schlaggar, B. L., & Petersen, S. E. (2012). Spurious but systematic correlations in functional connectivity MRI networks arise from subject motion. NeuroImage, 59(3), 2142–2154. http://doi.org/10.1016/j.neuroimage.2011.10.018
