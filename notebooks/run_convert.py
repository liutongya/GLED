import numpy as np
from floater import utils
import xarray as xr
from datetime import datetime
from tqdm import tqdm
#from floater import rclv
#import pickle
import sys
import os

mon = '01-01'

for year in np.arange(1993, 2020, 1):
    year_mon = str(year) + '-' + mon
    
    run_files = '/data/home/liutongya/RCLV/run_lavd/' + year_mon + '/'
    print(run_files)
    float_file_prefix = 'float_trajectories'
    out_dir = '/data/home/liutongya/RCLV/lavd_netcdf/' + year_mon + '/'
    output_prefix='float_trajectories'

    con_exist = os.path.exists(out_dir)

    if con_exist == False:
        print(year_mon)
        
        utils.floats_to_netcdf(input_dir=run_files, output_fname='float_trajectories', float_file_prefix='float_trajectories', output_dir=out_dir, output_prefix='float_trajectories', pkl_path='/data/home/liutongya/RCLV/run_lavd/BIN_files/floatset.pkl')
    
    else:
    
        print('Have converted to NC')