#!/bin/bash

##Auto construction of 3dttest++ and TFCE commands for DBIS investigation
##Will need to be adapted for use with VBM, more covariates and other cases, but should be adaptable


###TO DO

##Add ability to choose between randomise, afni or palm and this will auto set up analysis

subList=$1 #set to "all" if you want to include all subs with imaging data and a non-NA pheno value
#assume data is in /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging
imageExt=$2 #start with extension after subDir. Ex: /antCT/highRes_CorticalThicknessNormalizedToTemplate_blur8mm.nii.gz
phenoFile=$3 #location of phenotype file, has to have full subject name DMHDSXXXX
phenoCol=$4 #column in pheno file that contains main variable of interest, will always covary sex and assume first col is ID and second is sex
prefix=$5 #include img type, pheno contrast, and date. Ex: /mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/Max/EMH/results/cortThick_arteriolCaliber_071717
mask=$6
##only include sunjects without NA in pheno and with processed imaging
##eventually add a check for "good" imaging data from spenser QCs

if [[ $subList = "all" ]];then
	cut -d "," -f1 $phenoFile | tail -n +2 > ${prefix}.sublist.tmp
	subList=${prefix}.sublist.tmp
fi
imgList=""
afniList=""
rm -f ${prefix}_design.txt ${prefix}_afniCov.cov
phenoName=$(head -n1 $phenoFile | cut -d "," -f$phenoCol)
echo "subject sex $phenoName" > ${prefix}_afniCov.cov
for sub in $(cat $subList);do
	img=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/${imageExt}
	surfL=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/FreeSurfer/SUMA/std.60.lh.thickness.niml.dset
	surfR=/mnt/BIAC/munin2.dhe.duke.edu/Hariri/DBIS.01/Analysis/All_Imaging/${sub}/FreeSurfer/SUMA/std.60.rh.thickness.niml.dset
	pheno=$(grep $sub $phenoFile | cut -d "," -f${phenoCol})
	sex=$(grep $sub $phenoFile | cut -d "," -f2)
	if [[ $pheno != "NA" ]] && [[ -f $img ]];then
		##Make TCFE files		
		echo "$sex $pheno" >> ${prefix}_design.txt
		imgList="$imgList $img"
		##Make AFNI files
		afniList="$afniList $sub $img"
		surfListL="$surfListL $sub $surfL"
		surfListR="$surfListL $sub $surfR"
		echo "$sub $sex $pheno" >> ${prefix}_afniCov.cov
	else
		echo "skipping $sub ... missing pheno or img"
	fi
done
if [[ $pheno != "NA" ]] && [[ -f $img ]];then
		##Make TCFE files		
		echo "$sex $pheno" >> ${prefix}_design.txt
		imgList="$imgList $img"
		##Make AFNI files
		afniList="$afniList $sub $img"
		surfListL="$surfListL $sub $surfL"
		surfListR="$surfListL $sub $surfR"
		echo "$sub $sex $pheno" >> ${prefix}_afniCov.cov
fi
##Change sex back to 1 and 0
sed -i 's/female /0 /g' ${prefix}_design.txt
sed -i 's/male /1 /g' ${prefix}_design.txt
sed -i 's/female /0 /g' ${prefix}_afniCov.cov
sed -i 's/male /1 /g' ${prefix}_afniCov.cov
#handle FSL files
if [[ ! -f ${prefix}_allImgs.nii.gz ]];then
	3dTcat -prefix ${prefix}_allImgs.nii.gz $imgList
fi
printf "0 1\n0 -1\n" > ${prefix}_contrasts.txt
Text2Vest ${prefix}_design.txt ${prefix}_design.mat
Text2Vest ${prefix}_contrasts.txt ${prefix}_contrasts.con
echo "3dttest++ -setA groupTest $afniList -ETAC -mask $mask -covariates ${prefix}_afniCov.cov" > ${prefix}_afni3dttest++.sh
echo "3dttest++ -setA groupTest $surfListL -covariates ${prefix}_afniCov.cov" > ${prefix}_afni3dttestSurfL++.sh
echo "3dttest++ -setA groupTest $surfListR -covariates ${prefix}_afniCov.cov" > ${prefix}_afni3dttestSurfR++.sh
###Add in surface cortical thickness, Assuming you are doing thickness analyses

if [[ ! -f ${prefix}_results_tfce_corrp_tstat1.nii.gz ]];then
	randomise -i ${prefix}_allImgs.nii.gz -o ${prefix}_results -d ${prefix}_design.mat -t ${prefix}_contrasts.con -m $mask -n 500 -D -T
fi

rm ${prefix}_allImgs.nii.gz
rm ${prefix}*.tmp
