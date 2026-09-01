This repository contains MATLAB and R code used to process and analyse dorsal
CA1 recordings for the manuscript **“Time, but not reward, shapes replay-based
episodic prioritization”**, currently available as a
[bioRxiv preprint](https://doi.org/10.64898/2026.06.10.731494).

[*last updated: September 1st, 2026*]

## System requirements

- tested on MATLAB R2025b, requires the signal processing, statistics and machine learning, image processing and parallel computing toolboxes.
- tested with R-4.4.2, requires packages afex, emmeans, multcomp, dplyr, lmerTest, optimx, tidyverse, ggeffects, ggplot2
- run on a 64-bit Windows 11 machine.

No specialized hardware is required. A multicore workstation speeds up shuffle calculations.

## External dependencies

This code uses functions from the processing pipeline accompanying [`Tirole,
Huelin Gorriz et al. (2022)`](https://github.com/bendor-lab/Elife_Tirole_Huelin_Gorriz_2022)

The figures use Fabio Crameri's
[Scientific Colour Maps](https://www.fabiocrameri.ch/colourmaps/). The code
uses 
[Scientific Colour Maps 6](https://doi.org/10.5281/zenodo.4153113).

## Data

Data will be made publicly available upon publication.
The expected directory layout is:

```text
<data_folder>/
  RAT1/
    SESSION1/
      *.mat
    SESSION2/
      *.mat
    ...
  RAT2/
    SESSION1/
      *.mat
  ...
```

## Installation 

1. Clone or download this repository.
   
 ```text
   git clone https://github.com/margottirole/Tirole_et_al_TimeReplayPrioritization.git
   ```

2. Clone or download the eLife repository:

 ```text
 git clone https://github.com/bendor-lab/Elife_Tirole_Huelin_Gorriz_2022.git
 ```

3. Download and extract Scientific Colour Maps 6.
4. Download and extract the study data when available.
5. Open `ANALYSIS_PIPELINE.m` and set the local paths:

   ```matlab
   opts.data_folder    = 'C:\path\to\data';
   opts.elifeFolder    = 'C:\path\to\Elife_Tirole_Huelin_Gorriz_2022';
   opts.scriptsFolder  = 'C:\path\to\Tirole_et_al_TimeReplayPrioritization';
   opts.R_BIN          = 'C:\Program Files\R\R-4.4.2\bin\Rscript.exe'; % change to correct folder
   ```

Downloading the code and configuring the paths should normally take only a few
minutes, excluding MATLAB installation and data download.

## Instructions for use

After setting the paths and options at the beginning of
`ANALYSIS_PIPELINE.m`

1. Run the **REORGANISE DATA FOR CONVENIENCE** section once to organize the
   downloaded Figshare files into rat and session directories
2. Run the **MAIN PROCESSING OF DATA** section to perform behavioral processing,
   place-field calculation, Bayesian decoding, replay-event detection and
   directional replay analysis
  > *Warning: Replay significance is assessed against three shuffle
   > distributions with 1000 shuffles each and can take several hours per
   > session.*
3. run the **ANALYSIS** section to generate aggregated tables and statistics.
  Statistical summary tables are saved under 'opts.dataFolder\NEW_TABLES\...'
4. run the **MAKE FIGURES** section to reproduces panels from main figures