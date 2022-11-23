# A global Lagrangian eddy dataset based on satellite altimetry (GLED v1.0)
Tongya Liu and Ryan Abernathey

[![DOI](https://zenodo.org/badge/182862122.svg)](https://zenodo.org/badge/latestdoi/182862122)
[![Zenodo:Data](https://img.shields.io/badge/Zenodo:Data-10.5281/zenodo.2648855-blue.svg)](https://zenodo.org/record/2648855)

![Image text](scripts/fig_lavd.png)


## 1 Introduction

Code repository to reproduce the generation of GLED v1.0. 

## 2 Dataset description
This open-source dataset contains not only the general features (eddy center position, equivalent radius, rotation property, etc.) of eddies with lifetimes of 30, 90, and 180 days but also the trajectories of particles trapped by coherent eddies over the lifetime.

First, the general features of coherent eddies are provided in the file named eddy_info. 
- id: the eddy's ID
- date_start: generation date of the eddy
- duration: eddy lifespan (in days)
- radius: eddy radius (in km)
- cyc: 1 for anticyclonic and -1 for cyclonic
- center_lon, center_lat: the longitude and latitude of the eddy center with a frequency of 10 days
- dx, dy: zonal and meridional displacements (in km) over the eddy lifetime
- speed_x, speed_y: the zonal and meridional propagation speeds (in m/s) of the eddy
- lavd: values of Lagrangian-averaged vorticity deviation (LAVD)
- cd, ci: values of convexity deficiency (CD) and coherency index (CI)

Second, the trajectories of all Lagrangian particles inside the eddy boundary are provided in the file named eddy_traj. The particle positions every 10 days for each eddy are stored in an NC file with a three-dimensional array.


## 3 Data visualization
See the notebooks in *scripts*.