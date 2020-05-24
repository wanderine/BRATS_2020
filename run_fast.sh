#!/bin/bash

dataDir=/flush2/common/BRATS_2020/MICCAI_BraTS2020_TrainingData
outputDir=/flush2/common/BRATS_2020_FSL_segmentations

ten=10
hundred=100

Subject=1

MaxThreads=20
threads=0

for i in ${dataDir}/* ; do

    echo $i
    echo "Subject $Subject"

    if [ "$Subject" -lt "$ten" ]; then
        fast -o ${outputDir}/BraTS20_Training_00${Subject} ${i}/BraTS20_Training_00${Subject}_t1.nii & 	
    elif [ "$Subject" -lt "$hundred" ]; then
        fast -o ${outputDir}/BraTS20_Training_0${Subject} ${i}/BraTS20_Training_0${Subject}_t1.nii &
    else
        fast -o ${outputDir}/BraTS20_Training_${Subject} ${i}/BraTS20_Training_${Subject}_t1.nii &
    fi

    ((Subject++))
    
    ((threads++))
    if [ "$threads" -eq "$MaxThreads" ]; then
        wait
	threads=0
    fi

done
