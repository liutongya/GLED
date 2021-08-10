import xarray as xr
import numpy as np
from xmitgcm import open_mdsdataset
from xgcm import Grid

#---------------------
from xgcm.autogenerate import generate_grid_ds


dimXList = ['lon', 'longitude', 'LON', 'LONGITUDE', 'geolon', 'GEOLON',
            'xt_ocean']
dimYList = ['lat', 'latitude' , 'LAT', 'LATITUDE' , 'geolat', 'GEOLAT',
            'yt_ocean']

def write_field(fname, data):
    print('wrote to file: ' + fname)
    fid = open(fname, "wb")
    data.tofile(fid)
    fid.close()

def add_MITgcm_missing_metrics(dset, periodic=None, boundary=None):
    """
    Infer missing metrics from MITgcm output files.

    Parameters
    ----------
    dset : xarray.Dataset
        A dataset open from a file
    periodic : str
        Which coordinate is periodic
    boundary : dict
        Default boundary conditions applied to each coordinate

    Return
    -------
    dset : xarray.Dataset
        Input dataset with appropriated metrics added
    grid : xgcm.Grid
        The grid with appropriated metrics
    """
    coords = dset.coords
    grid   = Grid(dset, periodic=periodic, boundary=boundary)
    
    if 'drW' not in coords: # vertical cell size at u point
        coords['drW'] = dset.hFacW * dset.drF
    if 'drS' not in coords: # vertical cell size at v point
        coords['drS'] = dset.hFacS * dset.drF
    if 'drC' not in coords: # vertical cell size at tracer point
        coords['drC'] = dset.hFacC * dset.drF
    if 'drG' not in coords: # vertical cell size at tracer point
        coords['drG'] = dset.Zl - dset.Zl + dset.drC.values[:-1]
        # coords['drG'] = xr.DataArray(dset.drC[:-1].values, dims='Zl',
        #                              coords={'Zl':dset.Zl.values})
    
    if 'dxF' not in coords:
        coords['dxF'] = grid.interp(dset.dxC, 'X')
    if 'dyF' not in coords:
        coords['dyF'] = grid.interp(dset.dyC, 'Y')
    if 'dxV' not in coords:
        coords['dxV'] = grid.interp(dset.dxG, 'X')
    if 'dyU' not in coords:
        coords['dyU'] = grid.interp(dset.dyG, 'Y')
    
    if 'hFacZ' not in coords:
        coords['hFacZ'] = grid.interp(dset.hFacS, 'X')
    if 'maskZ' not in coords:
        coords['maskZ'] = coords['hFacZ']
        
    if 'yA' not in coords:
        coords['yA'] = dset.drF * dset.hFacC * dset.dxF
    
    # Calculate vertical distances located on the cellboundary
    # ds.coords['dzC'] = grid.diff(ds.depth, 'Z', boundary='extrapolate')
    # Calculate vertical distances located on the cellcenter
    # ds.coords['dzT'] = grid.diff(ds.depth_left, 'Z', boundary='extrapolate')
    
    metrics = {
        ('X',)    : ['dxG', 'dxF', 'dxC', 'dxV'], # X distances
        ('Y',)    : ['dyG', 'dyF', 'dyC', 'dyU'], # Y distances
        ('Z',)    : ['drW', 'drS', 'drC', 'drF', 'drG'], # Z distances
        ('X', 'Y'): ['rAw', 'rAs', 'rA' , 'rAz'], # Areas in X-Y plane
        ('X', 'Z'): ['yA']} # Areas in X-Z plane
    
    grid._assign_metrics(metrics)
    
    return dset, grid


path = '/data/home/liutongya/RCLV/velocity/run_offline/run/'
ds = open_mdsdataset(path, prefix={'Diag_stat'}).chunk()

grid = Grid(ds)

ds, grid = add_MITgcm_missing_metrics(ds, periodic='X', boundary={'Y':'extend'})

# psi is weighted by cell thickness buy phi is not!
# alternate way to get non-divergent velocity

# path to save the corr velocity
path_corr = '/data/home/liutongya/RCLV/velocity/vel_corr/'

for num in np.arange(9861):
    phi = ds.PhiVEL[num, :, :]

    u_phi = xr.where(ds.maskW, grid.derivative(phi, 'X'), 0)
    v_phi = xr.where(ds.maskS, grid.derivative(phi, 'Y'), 0)

    u_nd = (ds.UVEL[num, :, :] - u_phi).values.astype('>f4')
    v_nd = (ds.VVEL[num, :, :] - v_phi).values.astype('>f4')
    
    u_out = path_corr + 'uvel.' + str(num).zfill(10) + '.data'
    v_out = path_corr + 'vvel.' + str(num).zfill(10) + '.data'
    
    write_field(u_out, u_nd)
    write_field(v_out, v_nd)
    
    


