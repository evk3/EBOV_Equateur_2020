#!/bin/bash -l

#The purpose of this wrapper script is to submit
#the EBOV_assemble_genomes.sh script using all files in file_names.txt

files=$(awk 'END{print NR}' ./file_names.txt)
echo $files

#Submit script 1 to length of file_names.txt number of times, skip every other file when submitting.
qsub -t 1-$files:2 \
	-N EBOV \
	./EBOV_assemble_genomes.sh \

echo "Wrapper script done"

