import os
import sys
import numpy as np
import xarray as xr
from datetime import datetime
from tqdm import tqdm
from floater import rclv
import pickle

n_time = 12
rootfn = os.getcwd()[-7:]

base_dir= '/rigel/ocp/users/tl2913/global_RCLV/float_trajectories_lavd/'

fn = rootfn + '-01'

ddir = os.path.join(base_dir, fn + '_netcdf')
ds = xr.open_mfdataset(os.path.join(ddir, '*.nc'))

    
# R4 ------------------------------
xx0 = 175; xx1 = 360;
yy0 = -70; yy1 = 5;

lx0 = ds.sel(x0=slice(xx0,xx1), y0=slice(yy0,yy1)).x[0, :, :]
lx1 = ds.sel(x0=slice(xx0,xx1), y0=slice(yy0,yy1)).x[n_time, :, :]

ly0 = ds.sel(x0=slice(xx0,xx1), y0=slice(yy0,yy1)).y[0, :, :]
ly1 = ds.sel(x0=slice(xx0,xx1), y0=slice(yy0,yy1)).y[n_time, :, :]

lxt = (lx0.values, lx1.values)
lyt = (ly0.values, ly1.values)

lavd = ds.sel(x0=slice(xx0,xx1), y0=slice(yy0,yy1)).lavd[n_time].to_masked_array().filled(0)

# ci_th -1 cd 0.1
kwargs = dict(CI_th=-1, CI_tol=0.1, min_distance=13, min_limit_diff=1e-8,
              min_area=169, max_footprint=100000, use_threadpool=True, progress=True, convex_def=0.1, 
              max_width=100, min_peak=1e-6)

contours = list(rclv.find_convex_contours(lavd, lxt, lyt, **kwargs))

savename = fn + '_d' + str(n_time).zfill(2) + '0_R4.pickle'
with open(savename, 'wb') as f:
    pickle.dump(contours, f)