# Example of identifying 90-day RCLVs

import os
import sys
import numpy as np
import xarray as xr
import datetime
from tqdm import tqdm
from floater import rclv
import pandas as pd
import gsw
import pickle

# compute eddy area and radius according to different lat
# area: km^2 radius: km
def compute_radius(lat, num):
    lt = np.zeros((161, 2))
    lt[:, 0] = np.arange(-80, 80.1, 1)
    lt[:, 1] = np.arange(-80, 80.1, 1)
    ln = np.zeros((161, 2))
    for i in np.arange(161):
        ln[i, 0] = 0
        ln[i, 1] = 1
    l1 = gsw.distance(ln, lt, axis=1)
    l2 = gsw.distance(ln, lt, axis=0)

    bin_area = l1[:160] * l2[:, 0].T
    bin_area = bin_area[:, 0]

    lat0 = np.arange(-79.5, 80, 1)

    index = np.abs(lat0 - lat).argmin()
    area = bin_area[index] /1024 /1e6 * num
    # 1024 = 32 * 32
    radius = np.sqrt((bin_area[index] /1024 /1e6 * num)/ np.pi)
    
    return area, radius

#mon = 1
#mon_str = '01-01'
n_time = 9
duration = 90

R = 6.371e6 # Earth radius
lat_to_meters = np.pi*R/180
Om = 7.2921e-5 # rotation rate
sec_per_day = 24*60*60

data_path1 = '/data/home/liutongya/RCLV/data/eddyinfo/'
data_path2 = '/data/home/liutongya/RCLV/data/eddytraj/'

for year in np.arange(1993, 2020, 1):
    for mon in np.arange(3, 4, 1):
        
        mon_str = str(mon).zfill(2) + '-01'
        year_mon = str(year) + '-' + mon_str

        run_files = '/data/home/liutongya/RCLV/run_lavd/' + year_mon + '/'
        print(run_files)
        
        float_file_prefix = 'float_trajectories'
        out_dir = '/data/home/liutongya/RCLV/lavd_netcdf/' + year_mon + '/'
        output_prefix='float_trajectories'

        pkldir = '/data/home/liutongya/RCLV/contours/contours_pkl/'

        savename = pkldir + year_mon + '_D' + str(n_time * 10).zfill(3) + '.pickle'

        con_exist1 = os.path.exists(out_dir)
        con_exist2 = os.path.exists(savename)

        ncfn = out_dir + 'float_trajectories_netcdf/*.nc'
        ds = xr.open_mfdataset(ncfn)

        start_date = year_mon
        st_julian = datetime.datetime(year, mon, 1).toordinal()
        end_date = datetime.date.fromordinal(int(st_julian+duration)).strftime('%Y-%m-%d')

        lx0 = ds.x[0, :, :]
        lx1 = ds.x[n_time, :, :]

        ly0 = ds.y[0, :, :]
        ly1 = ds.y[n_time, :, :]

        lxt = (lx0.values, lx1.values)
        lyt = (ly0.values, ly1.values)

        lavd = ds.lavd[n_time].to_masked_array().filled(0)

        contours = pickle.load(open(savename, 'rb'))

        mask = rclv.label_points_in_contours(lavd.shape, [c[1] for c in contours])
        mask_da = xr.DataArray(mask, dims=['y0', 'x0'], name='mask', coords={'y0': ds.y0, 'x0': ds.x0})

        vort_tmp = ds.vort[n_time] * 1e6
        vort_avg = (vort_tmp.groupby(mask_da).mean(dim='stacked_y0_x0'))

        lavd_tmp = ds.lavd[n_time] * 1e6
        lavd_avg = (lavd_tmp.groupby(mask_da).mean(dim='stacked_y0_x0'))

        mask_uni = np.unique(mask)

        for i_rclv, (center, contour, pnum, cd, ci) in enumerate(contours):

            print(i_rclv)

            mask_value = i_rclv + 1

            if mask_value in mask_uni:

                cols=['id', 'date_start', 'date_end', 'duration', 'area', 'radius', 'cyc', 'center_lon', 
                      'center_lat', 'dx', 'speed_x', 'dy', 'speed_y', 'vort', 'lavd', 'cd', 'ci']

                df = pd.DataFrame(columns=cols)

                vort = vort_avg.sel(mask=mask_value).values.item()
                lavd_mean = lavd_avg.sel(mask=mask_value).values.item()

                eddy_id = '%s_%03dday_%06d' % (year_mon, duration, i_rclv+1)

                print(eddy_id)

                j, i = center
                center_traj = (ds[['x', 'y']].isel(time=slice(0, n_time+1), x0=i, y0=j)
                               .to_dataframe()[['x', 'y']].values.tolist())

                area, radius = compute_radius(center_traj[0][1], pnum)

                lat_mean = 0.5 * (center_traj[0][1] + center_traj[-1][1])
                lon_to_meters = lat_to_meters * np.cos(np.radians(lat_mean))

                delta_lon = center_traj[-1][0] - center_traj[0][0]
                delta_lat = center_traj[-1][1] - center_traj[0][1]

                displacement_x = delta_lon * lon_to_meters / 1e3    # km
                displacement_y = delta_lat * lat_to_meters / 1e3

                speed_x = displacement_x / (duration * sec_per_day) # km/s
                speed_y = displacement_y / (duration * sec_per_day)

                if vort > 0:
                    cyc = -1
                else:
                    cyc = 1

                data = {'id': eddy_id,
                        'date_start': start_date,
                        'date_end': end_date,
                        'duration': duration,
                        'area': area,
                        'radius': radius,
                        'cyc': cyc,
                        'center_lon': [tmp[0] for tmp in center_traj],
                        'center_lat': [tmp[1] for tmp in center_traj],
                        'dx': displacement_x,
                        'speed_x': speed_x,
                        'dy': displacement_y,
                        'speed_y': speed_y,
                        'vort': vort,
                        'lavd': lavd_mean,
                        'cd': cd,
                        'ci': ci
                }

                df = df.append(data, ignore_index=True)
                jsonstr = data_path1 + eddy_id + '.json'
                df.to_json(jsonstr)

                region = (ds[['x', 'y']].isel(time=slice(0, n_time+1)).where(mask_da==mask_value, drop=True).load())

                ncstr = data_path2 + eddy_id + '.nc'
                region.to_netcdf(ncstr)

