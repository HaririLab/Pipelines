#!/bin/bash

#Process epi for future processing with task or rest pipeline

###Requires T1 pipeline to have been run


##Current Ideas

#run 3dvolreg,3dAutomask, align_centers to a sub struct that is rigidly aligned to MNI space, run align_epitoAnat.py, then apply nonlinear warp from antsCT pipeline.


