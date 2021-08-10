import numpy as np
from floater import utils
import xarray as xr
from datetime import datetime
from tqdm import tqdm
from floater import rclv
import pickle
import sys
import os
 
dirfn = sys.argv[1]

run_files = '/data/home/liutongya/RCLV/run_lavd/' + dirfn + '/'
print(run_files)
float_file_prefix = 'float_trajectories'
out_dir = '/data/home/liutongya/RCLV/lavd_netcdf/' + dirfn + '/'
output_prefix='float_trajectories'

con_exist = os.path.exists(out_dir)

if con_exist == False:
    
    utils.floats_to_netcdf(input_dir=run_files, output_fname='float_trajectories', float_file_prefix='float_trajectories', output_dir=out_dir, output_prefix='float_trajectories', pkl_path='/data/home/liutongya/RCLV/run_lavd/BIN_files/floatset.pkl')
    
else:
    
    print('Have converted to NC')
    
ncfn = out_dir + 'float_trajectories_netcdf/*.nc'
ds = xr.open_mfdataset(ncfn)

n_time = 3

lx0 = ds.x[0, :, :]
lx1 = ds.x[n_time, :, :]

ly0 = ds.y[0, :, :]
ly1 = ds.y[n_time, :, :]

lxt = (lx0.values, lx1.values)
lyt = (ly0.values, ly1.values)

lavd = ds.lavd[n_time].to_masked_array().filled(0)

# ci_th -1 cd 0.1
kwargs = dict(CI_th=-1, CI_tol=0.1, min_distance=13, min_limit_diff=1e-8,
              min_area=169, max_footprint=100000, use_threadpool=True, progress=True, convex_def=0.1, 
              max_width=100, min_peak=1e-6)

contours = list(rclv.find_convex_contours(lavd, lxt, lyt, **kwargs))

pkldir = '/data/home/liutongya/RCLV/contours/contours_pkl/'

savename = pkldir + dirfn + '_D' + str(n_time * 10).zfill(3) + '.pickle'

with open(savename, 'wb') as f:
    pickle.dump(contours, f)
