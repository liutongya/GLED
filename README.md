# A global Lagrangian eddy dataset based on satellite altimetry (GLED v1.0)
Tongya Liu and Ryan Abernathey

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7349753.svg)](https://doi.org/10.5281/zenodo.7349753)
[![Zenodo:Data](https://img.shields.io/badge/Zenodo:Data-10.5281/zenodo.7349753-blue.svg)](https://zenodo.org/record/7349753)

![Image text](scripts/fig_lavd.png)


## 1 Introduction

Millions of Lagrangian particles are advected by satellite-derived surface geostrophic velocities over a period of 1993-2019. Using the method of Lagrangian-averaged vorticity deviation by Haller et al. (2016), we present a global Lagrangian eddies dataset (GLED v1.0). The greatest strength of GLED v1.0 is that the identified eddies are all material objects by construction. Our eddy dataset provides an additional option for oceanographers in studying the interaction between coherent eddies and other physical or biochemical processes in the Earth system. In this repostory, we provide the related algorithms to reproduce the generation of GLED v1.0 and detailed examples of using this dataset.  

## 2 Dataset description
This open-source dataset contains not only the general features (eddy center position, equivalent radius, rotation property, etc.) of eddies with lifetimes of 30, 90, and 180 days but also the trajectories of particles trapped by coherent eddies over the lifetime.

First, the general features of coherent eddies are stored in the JSON file in the directory named “eddyinfo”. 
- id: the eddy's ID
- date_start: generation date of the eddy
- duration: eddy lifespan (in days)
- radius: eddy radius (in km)
- cyc: 1 for anticyclonic and -1 for cyclonic
- center_lon, center_lat: the longitude (in degrees east) and latitude (in degrees north) of the eddy center with a frequency of 10 days
- dx, dy: zonal and meridional displacements (in km) over the eddy lifetime
- speed_x, speed_y: the zonal and meridional propagation speeds (in m/s) of the eddy
- vort: relative vorticity (in s^-1)
- lavd: values of Lagrangian-averaged vorticity deviation (LAVD, in s^-1)

Second, the trajectories of all Lagrangian particles inside the eddy boundary are provided in the directory named “eddytraj”. The particle positions every 10 days for each eddy are stored in an NC file with a three-dimensional array. 


## 3 Data visualization
See the notebooks in *scripts*.