#!/bin/sh
#
#SBATCH --account=ocp
#SBATCH --job-name=lagrangian_advection
#SBATCH --time=08:00:00
#SBATCH --exclusive
#SBATCH --nodes=8

BINDIR="/rigel/ocp/users/tl2913/global_RCLV/BIN_files"
FLOATFILE="flt_ini_pos_rec.global.32deg_f4.bin"
#LOCALDIR="/local/mitgcm/"
LOCALDIR="/local"

# transfer files to local ssd drive
#sbcast -v -f $BINDIR/$FLOATFILE $LOCALDIR/$FLOATFILE.copy

module add anaconda/3-4.4.0
source activate geo_scipy
mpirun python copy_files_to_local_dir.py
source deactivate
module rm anaconda/3-4.4.0

RUNDIR=$SLURM_SUBMIT_DIR
echo "Running MITgcm in $RUNDIR"
cd $RUNDIR

module add intel-parallel-studio/2017 netcdf-fortran/4.4.4 netcdf/gcc/64/4.4.0
mpirun -n 128 ./mitgcmuv

## Store the output

# this should be something like 2010-05-01
CODE=$( basename $( pwd ) )
#CODE="2010-05-01"

PICKLEPATH="../../pkl_files/flt_ini_pos_rec.global.32deg_f4.pkl"
module add anaconda/3-4.4.0
source activate geo_scipy
floater_convert --output_format netcdf --ref_time $CODE --pkl_path $PICKLEPATH ../../float_trajectories_lavd/$CODE

# clean up the run but keep the main log file
mv STDOUT.0000 tmp
rm *.data *.meta STD* *.csv
mv tmp STDOUT.0000

