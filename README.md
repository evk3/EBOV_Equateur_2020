# EBOV_Equateur_2020

This repository contains scripts that were used in the manuscript, "Field and Molecular Epidemiology of the 2020 Ebola virus disease outbreak in Equateur Province, Democratic Republic of the Congo" by Kiganda-Lusamaki et al.


## Read mapping script

This script accepts *.fastq.gz files as input and generated consensus viral genomes by performing a read mapping.  The  list of input file names is provided in "file_names.txt" and a wrapper script "array_wrapper_script.sh" submits each set of files (R1 and R2) to a Sun Grid Engine scheduler node for read mapping.  Read mapping heavy lifting is done by the "EBOV_assemble_genomes.sh" script.
