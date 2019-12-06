# Scientific code base for the paper "Intensity correlations in music performances"

This codebase is written in Julia and reproduces our paper in its entirety, provided that the raw data are first downloaded. To install this project use the `Project.toml` file (it is assumed that you know how to use Julia in order to use this codebase).

Please save the raw data in directory `data/exp_raw`, while having subfolders for each of the four datasets named `uwe, playalongs, tapping, pgmusic`.

The folder `paperfigs` contains the figure generating files (that also do all of the data processing actually). Only the `scripts/all_psds.jl` file needs to be run before-hand, which calculates the PSD exponents.
