#!/bin/sh
#
#SBATCH --account=ocp
#SBATCH --time=10:00:00
#SBATCH --exclusive
#SBATCH --nodes=1

module add anaconda/3-4.4.0
source activate geo_scipy
mpirun python detection_D120.py
source deactivate
module rm anaconda/3-4.4.0