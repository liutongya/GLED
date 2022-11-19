# The setup of the offline model run

import numpy as np
import xarray as xr
import numpy as np
import pandas as pd
import os
import shutil

# where to find the template for the run directory
template_dir = 'template'

# where to find the offline velocities
offline_vel_dir = ('/data/home/liutongya/RCLV/velocity/vel_corr')
vel_components = ['uvel', 'vvel']

# destination within run directory in which to link the offline velocities
offline_run_dir = 'offline_velocities'

# number of days of velocities to link in each experiment
ndays_expt = 182

def new_run(run_code, offline_time_offset):
    shutil.copytree(template_dir, run_code, symlinks=True)
    for n in range(ndays_expt):
        true_timestep = n + offline_time_offset
        for comp in vel_components:
            src = os.path.join(offline_vel_dir,
                               '%s.%010d.data' % (comp, true_timestep))
            dir_off = run_code + '/offline_velocities/'
            
            print(src)
            dest = os.path.join(run_code, offline_run_dir,
                                '%s.%010d.data' % (comp, n))
            
            print(dest)
            #os.makedirs(dir_off)
            if os.path.exists(dir_off)==0:
                os.makedirs(dir_off)
                
            os.symlink(src, dest)
            #shutil.copyfile
            #os.system('cp $src $dest')
            #shutil.copyfile(src, dest)

first_date = '1993-01-01'
# we can go six months out from there
last_date = '2019-06-01'

first_of_each_month = pd.date_range(first_date, last_date, freq='MS')

for start_date in first_of_each_month:
    day_offset = (start_date - first_of_each_month[0]).days
    code = start_date.strftime('%Y-%m-%d')

    print('%s: %d' % (code, day_offset))
    
    new_run(code, day_offset)
