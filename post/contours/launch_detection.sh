#!/bin/bash

month='01'

for year in `seq 2012 2015`
do
	dir="$year-$month"
	echo $dir
	skip=0
	rundir="$dir"
        if [ ! -d $rundir ]; then
		mkdir $rundir
		echo "created $rundir"
	fi
	rootfile="/rigel/ocp/users/tl2913/global_RCLV/detection/contours_output"
	tempfn="$rootfile/template/*"
	runfn="$rootfile/$rundir/"
	cp $tempfn $runfn
    cd $dir
#    rm -f slurm-*
    sbatch --job-name=$dir sbatch_detection_D030.sh
    sbatch --job-name=$dir sbatch_detection_D060.sh
    sbatch --job-name=$dir sbatch_detection_D090.sh
    sbatch --job-name=$dir sbatch_detection_D120.sh
    sbatch --job-name=$dir sbatch_detection_D150.sh
    sbatch --job-name=$dir sbatch_detection_D180.sh
    cd ..
done
