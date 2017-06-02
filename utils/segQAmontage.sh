#!/bin/bash

##################################segQAmontage.sh##############################
####################### Authored by Max Elliott 6/2/2017 ####################

####Description####
#originally created to aid in QAing Freesurfer segmentations in the way Enigma suggests, makes a 2x2 montage of pial surface with segmentation loaded

npb=13
subDir=$1 ##Path to a subjects Directory in All_imaging
image=${subDir}/FreeSurfer/SUMA/std.60.lh.aparc.a2009s.annot.niml.dset
surf=$(subDir}/FreeSurfer/SUMA/std.60.FreeSurfer_both.spec
prefix=${subDir}/QA/segQAmontage
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


suma -niml -npb $npb -spec $surf &

DriveSuma -npb $npb -com surf_cont -switch_surf lh.pial
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/pialViewLateral.niml.vvs
DriveSuma -npb $npb -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9

DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png

DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/pialViewMedial.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp3.png
DriveSuma -npb $npb  -com viewer_cont -key ] \
	-com viewer_cont -key [ \
  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp4.png
  
imcat -prefix $prefix -matrix 2 2 tmp*.png

convert $prefix.ppm $prefix.png
rm tmp*.png $prefix.ppm
 
