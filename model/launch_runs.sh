#!/bin/bash

month='12-01'

for year in `seq 1993 2016`
do
	dir="$year-$month"
	echo $dir
	skip=0
	datadir="../float_trajectories_lavd/$dir""_netcdf"
	if [ -d $datadir ]
	then
		filecount=`ls $datadir | wc -l`
		if [ $filecount -eq 7 ]
		then
			echo "  output files present"
			skip=1
		fi
	fi
	if [ $skip -ne 1 ]
	then
		echo "  launching run"
		cd $dir
		sbatch --job-name=$dir SBATCH_run_script_habanero.sh
		cd ..
	fi
done
