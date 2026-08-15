# Source data

## Data source

This project uses publicly funded MAST research data obtained from the **UK Atomic Energy Authority (UKAEA) Open Data Portal** for **MAST shot 27643**.

Source portal: https://opendata.ukaea.uk/mast-data/

UKAEA End User Licence: https://opendata.ukaea.uk/license/

## Required local files

The MATLAB workflow was developed using:

- `amc27643.nc` — magnetics / plasma current
- `anb27643.nc` — neutral beam injection power
- `anu27643.nc` — neutron rate and supplied error array
- `ant27643.nc` — supporting diagnostic/derived data inspected during the project

## Why the raw data are not included

The original UKAEA NetCDF files are deliberately **not redistributed through this Git repository**. The UKAEA End User Licence governs access, use, acknowledgement and onward sharing of the data collections and derived material.

To reproduce the project, obtain the relevant files directly from UKAEA under the applicable End User Licence and any Special Conditions supplied with the data.

The repository also omits the full cleaned/aligned derivative dataset. The MATLAB scripts document how that dataset is generated locally from the UKAEA source files.

## Data status and attribution

UKAEA supplies the data collections on an **"as is"** basis and disclaims responsibility for their accuracy or comprehensiveness. Any dataset-specific validation notices, distribution notes, metadata and Special Conditions supplied by UKAEA should be reviewed and retained by users.

The experimental source data are UKAEA data. The MATLAB processing workflow, analysis, modelling and interpretation in this repository were independently produced by **Liam Birch** for a personal portfolio/educational project and are not official UKAEA analysis.
