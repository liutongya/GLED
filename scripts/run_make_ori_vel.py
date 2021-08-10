import xarray as xr
import numpy as np

def write_field(fname, data):
    print('wrote to file: ' + fname)
    fid = open(fname, "wb")
    data.tofile(fid)
    fid.close()

# load the aviso dataset from 1993 to 2019
path = '/data/data_pub/dataset-duacs-rep-global-merged-allsat-phy-l4/merged/*.nc'
ds = xr.open_mfdataset(path)

# path to save the original velocity
path_ori = '/data/home/liutongya/RCLV/velocity/vel_ori/'

# interplate to 0.1-degree grid
lon_new = np.linspace(0, 360, 3600)
lat_new = np.linspace(-80, 80, 1600)

for num in np.arange(9861):
#for num in np.arange(181):

    u_new = ds.ugos[num, :, :].interp(longitude=lon_new, latitude=lat_new).fillna(0).values.astype('>f4')
    v_new = ds.vgos[num, :, :].interp(longitude=lon_new, latitude=lat_new).fillna(0).values.astype('>f4')
    
    u_out = path_ori + 'uvel.' + str(num).zfill(10) + '.data'
    v_out = path_ori + 'vvel.' + str(num).zfill(10) + '.data'
    
    write_field(u_out, u_new)
    write_field(v_out, v_new)