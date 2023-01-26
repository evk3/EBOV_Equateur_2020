# EBOV_Equateur_2020

This repository contains scripts that were used in the manuscript, "Field and Molecular Epidemiology of the 2020 Ebola virus disease outbreak in Equateur Province, Democratic Republic of the Congo" by Kiganda-Lusamaki et al.


## Read mapping script

This script accepts *.fastq.gz files as input and generated consensus viral genomes by performing a read mapping.  The  list of input file names is provided in "file_names.txt" and a wrapper script "array_wrapper_script.sh" submits each set of files (R1 and R2) to a Sun Grid Engine scheduler node for read mapping.  Read mapping heavy lifting is done by the "EBOV_assemble_genomes.sh" script.


## Bayesian Branch Rate Estimates

The samogitia_subrate.py script was originally from Gytis Dudas.  If you don't know him, he does amazing work!  Check him out [here](https://github.com/evogytis).  The samogitia.py script was orignally modified by Jason Ladner (for EBOV semen sequencing rate estimates) and re-used to calculate the branch rate estimates from all available Mbandaka sequences, only Tumba 2018 sequences, or only the branch leading to the Tumba-like re-emerged EBOV variant.
