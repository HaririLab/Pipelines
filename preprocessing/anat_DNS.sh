#!/bin/bash
#
# Script: anat_DNS.sh
# Purpose: Pipeline for processing T1 anatomical images for the DNS study
# Author: Maxwell Elliott
#


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1)make citations #citations
#2)Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later

###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!###########################

###############################################################################
#
# Environment set up
#
###############################################################################

sub=$1 #$1 or flag -s  #20161103_21449 #pipenotes= Change away from HardCoding later 
subDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/${sub} #pipenotes= Change away from HardCoding later
QADir=${subDir}/QA
antDir=${subDir}/antCT
freeDir=${subDir}/FreeSurfer
tmpDir=${antDir}/tmp
antPre="highRes_" #pipenotes= Change away from HardCoding later
templateDir=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500 #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI #pipenotes= update/Change away from HardCoding later
#T1=$2 #/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_006.nii.gz #pipenotes= update/Change away from HardCoding later
threads=1 #default in case thread argument is not passed
threads=$2
export PATH=$PATH:/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/Pipelines/scripts/:/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/ants-2.2.0/bin//mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/ants-2.2.0/bin/ #add dependent scripts to path #pipenotes= update/Change to DNS scripts
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
export OMP_NUM_THREADS=$threads
export ANTSPATH=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/ants-2.2.0/bin/

T1pre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f3 | sed 's/ //g')
if [[ $T1pre == "not_collected" || $T1pre == "dont_use" ]];then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!NO T1, Trying to Run on Coplanar so that EPIs might be salvaged!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!Make sure you know what you are doing if you use this sub in any analysis!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	T1pre=$(grep $sub /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f2 | sed 's/ //g')
	echo "Make sure you know what you are doing if you use this sub in any analysis" > ${antDir}/000000.COPLANARnotT1.00000000
	echo "Make sure you know what you are doing if you use this sub in any analysis" > ${freeDir}/000000.COPLANARnotT1.00000000
fi

##Set up directory
mkdir -p $QADir
cd $subDir
mkdir -p $antDir
mkdir -p $tmpDir
export SUBJECTS_DIR=${subDir} #pipenotes= update/Change away from HardCoding later also figure out FS_AVG stuff
export FREESURFER_HOME=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/freesurfer

if [[ ! -f ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate.nii.gz ]];then

	if [[ ${T1pre} == *.nii.gz ]];then
		T1=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/${T1pre}
	else
		###Check to make sure T1 has correct number of slices other exit and complain
		lenT1=$(ls /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm | wc -l)
		if [[ $lenT1 == 162 ]];then
			to3d -anat -prefix tmpT1.nii.gz /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm
			mv tmpT1.nii.gz ${tmpDir}/
			T1=${tmpDir}/tmpT1.nii.gz
		else
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!T1 is the Wrong Size, wrong number of slices!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Make Sure you Know what you are doing!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
			to3d -anat -prefix tmpT1.nii.gz /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm
			mv tmpT1.nii.gz ${tmpDir}/
			T1=${tmpDir}/tmpT1.nii.gz
		fi
	fi

	###Rigidly align, to avoid future processing issues
	antsRegistrationSyN.sh -d 3 -t r -f ${templateDir}/${templatePre}.nii.gz -m $T1 -n $threads -o ${antDir}/${antPre}r

	#Make Montage of sub T1 brain extraction to check quality

	echo ""
	echo "#########################################################################################################"
	echo "########################################ANTs Cortical Thickness##########################################"
	echo "#########################################################################################################"
	echo ""
	###Run antCT
	antsCorticalThickness.sh -d 3 -a ${antDir}/${antPre}rWarped.nii.gz -e ${templateDir}/${templatePre}.nii.gz -m ${templateDir}/${templatePre}_BrainCerebellumProbabilityMask.nii.gz -p ${templateDir}/${templatePre}_BrainSegmentationPosteriors%d.nii.gz -t ${templateDir}/${templatePre}_Brain.nii.gz -o ${antDir}/${antPre}
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Skipping antCT, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi

if [[ ! -f ${QADir}/anat.BrainExtractionCheckAxial.png ]];then
	echo ""
	echo "#########################################################################################################"
	echo "####################################Make QA montages######################################"
	echo "#########################################################################################################"
	echo ""
	##Make Cortical Thickness QA montage
	ConvertScalarImageToRGB 3 ${antDir}/${antPre}CorticalThickness.nii.gz ${tmpDir}/corticalThicknessRBG.nii.gz none red none 0 1 #convert for Ants Montage
	3dcalc -a ${tmpDir}/corticalThicknessRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/corticalThicknessRBGstep.nii.gz 
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/corticalThicknessRBG.nii.gz -o ${QADir}/anat.antCTCheck.png -a 0.35 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/corticalThicknessRBGStep.nii.gz -f 0x1  #Create Montage taking images in axial slices every 5 slices
	###Make Brain Extraction QA montages
	ConvertScalarImageToRGB 3 ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${tmpDir}/highRes_BrainRBG.nii.gz none red none 0 10
	3dcalc -a ${tmpDir}/highRes_BrainRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/highRes_BrainRBGstep.nii.gz
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/highRes_BrainRBG.nii.gz -o ${QADir}/anat.BrainExtractionCheckAxial.png -a 0.5 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/highRes_BrainRBGstep.nii.gz -f 0x1
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/highRes_BrainRBG.nii.gz -o ${QADir}/anat.BrainExtractionCheckSag.png -a 0.5 -t -1x-1 -d 0 -p mask -s [5,mask,mask] -x ${tmpDir}/highRes_BrainRBGstep.nii.gz -f 0x1
fi
if [[ ! -f ${freeDir}/surf/rh.pial ]];then
	###Prep for Freesurfer with PreSkull Stripped
	#Citation: followed directions from https://surfer.nmr.mgh.harvard.edu/fswiki/UserContributions/FAQ (search skull)
	echo ""
	echo "#########################################################################################################"
	echo "#####################################FreeSurfer Surface Generation#######################################"
	echo "#########################################################################################################"
	echo ""
	rm -r ${freeDir}
	mksubjdirs FreeSurfer
	cp -R ${FREESURFER_HOME}/subjects/fsaverage ${subDir}/
	mri_convert ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${freeDir}/mri/001.mgz
	#Run 
	recon-all -autorecon1 -noskullstrip -s FreeSurfer -openmp $threads
	cp ${freeDir}/mri/T1.mgz ${freeDir}/mri/brainmask.auto.mgz
	cp ${freeDir}/mri/brainmask.auto.mgz ${freeDir}/mri/brainmask.mgz
	recon-all -autorecon2 -autorecon3 -s FreeSurfer -openmp $threads
	recon-all -s FreeSurfer -localGI
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping FreeSurfer, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi
#Run SUMA
if [[ ! -f ${freeDir}/SUMA/std.60.lh.area.niml.dset ]];then
	echo ""
	echo "#########################################################################################################"
	echo "######################################Map Surfaces to SUMA and AFNI######################################"
	echo "#########################################################################################################"
	echo ""
	cd ${freeDir}
	rm -r ${freeDir}/SUMA
	##Add back missing orig files
	mri_convert ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${freeDir}/mri/001.mgz
	mri_convert ${freeDir}/mri/001.mgz ${freeDir}/mri/orig.mgz
	mkdir ${freeDir}/orig
	@SUMA_Make_Spec_FS_lgi -NIFTI -ld 60 -sid FreeSurfer
	#Convert to GIFTIs for potential use with PALM for TFCE
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.thickness
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.thickness
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping SUMA_Make_Spec, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi

#cleanup
#mv highRes_* antCT/ #pipeNotes: add more deletion and clean up to minimize space, think about deleting Freesurfer and some of SUMA output
rm -r ${antDir}/tmp ${freeDir}/SUMA/lh.* ${freeDir}/SUMA/rh.* ${freeDir}/SUMA/FreeSurfer_.*spec #${freeDir}/bem ${freeDir}/label ${freeDir}/morph ${freeDir}/mpg ${freeDir}/mri ${freeDir}/rgb ${freeDir}/src ${freeDir}/surf ${freeDir}/tiff ${freeDir}/tmp ${freeDir}/touch ${freeDir}/trash 
rm ${antDir}/${antPre}BrainNormalizedToTemplate.nii.gz ${antDir}/${antPre}TemplateToSubject*
gzip ${freeDir}/SUMA/*.nii 
 
