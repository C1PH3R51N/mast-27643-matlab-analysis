# MAST Shot 27643 — MATLAB Diagnostic Data Analysis

## Project Authorship

**Independent analysis and MATLAB implementation by Liam Birch.**

This repository documents a personal portfolio project completed by Liam Birch using publicly funded MAST research data made available through the UK Atomic Energy Authority (UKAEA) Open Data Portal.

UKAEA supplied the source experimental data. **UKAEA did not perform, commission, endorse, validate, or approve the analysis in this repository.** The MATLAB code, data-processing workflow, modelling choices, statistical analysis, visualisations, interpretation, and portfolio documentation are the author's own work unless explicitly stated otherwise.

## Project objective

The project demonstrates an end-to-end scientific data-analysis workflow in MATLAB using MAST shot 27643. The analysis examines plasma current, neutral beam injection (NBI) power and neutron production, progressing from raw NetCDF inspection through data cleaning, time alignment, exploratory analysis, uncertainty assessment and Monte Carlo simulation.

The emphasis is on demonstrating reproducible analytical reasoning and MATLAB capability rather than presenting the repository as an official UKAEA scientific analysis.

## Source data

The analysis uses MAST shot 27643 diagnostic data obtained from the UKAEA Open Data Portal.

Required source files used during the project include:

| File | Diagnostic role | Primary use in this project |
|---|---|---|
| `amc27643.nc` | Magnetics | Plasma current |
| `anb27643.nc` | Neutral Beam Injection | Total NBI power |
| `anu27643.nc` | Neutron diagnostic | Neutron rate and supplied error array |
| `ant27643.nc` | Supporting/derived diagnostic | Supporting inspection context |

The original NetCDF files are **not redistributed in this repository**. Obtain source data directly from the UKAEA MAST Open Data Portal and review the licence and any dataset-specific conditions before use.

- UKAEA MAST Open Data: https://opendata.ukaea.uk/mast-data/
- UKAEA End User Licence: https://opendata.ukaea.uk/license/

## UKAEA data-use notice

UKAEA's End User Licence states that data collections may be used and personally copied for not-for-profit research, teaching, or personal educational development, with permission required for commercial use. It also requires acknowledgement/citation of the relevant data creators, funders and data service provider in publications, according to the distribution notes or accompanying metadata.

The licence also restricts onward access to the data collections, or material derived from them, except in specified circumstances. For that reason this repository is intentionally designed **not to redistribute the original NetCDF data or the full cleaned/aligned derivative dataset**. Users should obtain the source data from UKAEA under the applicable licence and reproduce the processing locally using the MATLAB scripts.

The UKAEA licence states that the data are supplied on an **"as is"** basis and without warranty as to accuracy or comprehensiveness. Any additional validation statements or special conditions supplied with the requested MAST dataset should also be retained and followed.

## Analysis workflow

1. Inspect NetCDF hierarchy, variables and metadata.
2. Profile raw diagnostic data for dimensions, missing values, ranges and sampling intervals.
3. Visualise the unprocessed signals.
4. Select the 0.00–0.50 s analysis window.
5. Clean and align diagnostics onto a common 0.0002 s time grid.
6. Perform exploratory statistics and operating-phase comparisons.
7. Investigate relationships using correlation, cross-correlation and NBI step-response analysis.
8. Assess the supplied neutron error data and inspect its metadata.
9. Perform single-point and full time-series Monte Carlo sensitivity analysis.
10. Export numerical summaries and document the analytical conclusions and limitations.

## Key results

The final analysis produced:

- **2,501** aligned observations.
- Plasma current vs neutron rate correlation: **r = 0.6555**.
- NBI power vs neutron rate correlation: **r = 0.4196**.
- Measured peak neutron rate: **1.0610 × 10^14 n/s** at **0.349600 s**.
- Phase 1 mean neutron rate: **4.4338 × 10^13 n/s**.
- Phase 2 mean neutron rate: **6.6155 × 10^13 n/s**.
- Measured Phase 1 → Phase 2 increase: **49.206%**.
- Monte Carlo mean Phase 1 → Phase 2 increase: **49.216%**.
- Monte Carlo 95% simulation interval for phase increase: **48.094%–50.314%**.
- Monte Carlo 95% peak-time interval: **0.325400–0.400200 s**.

These are outputs of the author's analysis and should **not** be interpreted as official UKAEA results.

## Monte Carlo assumptions and limitations

The source `ANU_ERRORS` variable is labelled as an error array, but the inspected NetCDF metadata did not define it as a standard deviation, standard error, confidence interval, or other specific statistical quantity.

For the portfolio sensitivity analysis:

- `ANU_ERRORS` was treated as an **assumed 1σ Gaussian uncertainty**.
- Measurement errors were assumed **independent between time points** because covariance information was not available.
- Monte Carlo outputs are therefore conditional on these assumptions and are **not presented as a formally validated uncertainty model**.
- The simulated raw maximum was found to be upward-biased because maximising across many independently perturbed samples preferentially selects positive noise excursions. It was therefore treated as a sensitivity result, not as a corrected physical peak estimate.

## Repository structure

```text
mast-27643-matlab-analysis/
├── README.md
├── .gitignore
├── src/          MATLAB scripts added by the author
├── data/         source-data instructions only; no UKAEA data redistributed
├── results/      summary-level outputs only
├── figures/      author-generated analysis figures/screenshots
└── docs/         author's portfolio report (to be added)
```

## MATLAB scripts

The completed `.m` files will be added to `src/`. The intended workflow is documented in [`src/README.md`](src/README.md).

## Reproducibility

The primary analysis window is **0.00–0.50 s** with a common time step of **0.0002 s**. Monte Carlo scripts use the fixed seed `rng(27643)` for reproducibility.

To reproduce the project, obtain the required source data directly from UKAEA, place the files in a local data directory, and run the scripts in the documented order.

## Portfolio report

The author will add a separately formatted portfolio report to `docs/`. The report is the author's own explanation of the MATLAB workflow, analytical decisions, results and limitations.

## Attribution

**Source experimental data:** UK Atomic Energy Authority (UKAEA), MAST Open Data Portal, MAST shot 27643.

**Independent MATLAB analysis, processing, modelling, visualisation and interpretation:** Liam Birch.

This repository is not an official UKAEA repository and should not be presented as representing UKAEA's conclusions or endorsement.

## Licensing note

No blanket licence is applied here to the UKAEA source data or data-derived material. Source-data use remains subject to the UKAEA End User Licence and any applicable Special Conditions or metadata supplied with the dataset.

If a separate licence is later applied to the author's original MATLAB source code, it should be clearly scoped to that original code and should not be interpreted as relicensing UKAEA data or restricted derivative material.
