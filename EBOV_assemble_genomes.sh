#!/bin/bash -l
## Grid Engine Example Job Script  

# -- Begin SGE embedded arguments --
#$ -V
#Pass all environment variables to job
#$ -cwd
#Use current working directory

#$ -N EBOV
# Name of script

#$ -j y
#Combine standard error and output files.

#$-q short.q
#Use the all.q queue, and not any other queue.

#$-pe smp 2
#Ask for a parallel environment for multi-threading.

# -- End SGE embedded arguments --

module load bwa/0.7.17
module load samtools/1.9
module load picard/2.21.1
module load BEDTools/2.27.1
module load cutadapt/2.3
module load prinseq/0.20.3
module load htslib/1.9
module load bowtie2/2.3.5.1
module load gatk/4.1.7.0
module load htslib/1.10
module load gcc/9.2.0
module load SPAdes/3.14.0
module load Python3/3.7
module load java/latest


# create temp directory for work on /scratch

mkdir -p /scicomp/scratch/evk3/EBOV/
scratch='/scicomp/scratch/evk3/EBOV'

echo "Hostname:" $HOSTNAME
echo "SGE Value " $SGE_TASK_ID

OUTPUT_PATH=./mapping_output_NoIterate/
echo "Output path: " $OUTPUT_PATH

REFERENCE_PATH=./MBK481.fasta
cp $REFERENCE_PATH $scratch/
REFERENCE=$(sed -r 's/\.\/(.*$)/\1/g' <<< "$REFERENCE_PATH")

echo "Reference: " $REFERENCE

SEEDFILE=./file_names.txt
file_num=$(awk "NR==$SGE_TASK_ID" $SEEDFILE)

echo "First File" $file_num

sample_num=$(sed -r 's/_.*$//g' <<< "$file_num")
echo "Sample number is: " $sample_num

L1_READ1=$file_num
L1_READ2=$(awk "NR==($SGE_TASK_ID + 1)" $SEEDFILE)

echo $L1_READ1
echo $L1_READ2


#Remove Illumina TruSeq adaptors from PE reads:
echo "Starting cutadapt"
cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
         -A AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
         --cores=$NSLOTS \
         -m 1 \
         -o "$scratch"/"$sample_num"_R1_cutadapt.fastq.gz -p "$scratch"/"$sample_num"_R2_cutadapt.fastq.gz \
         $L1_READ1 $L1_READ2 

echo "Gunzipping now!"
gunzip -c "$scratch"/"$sample_num"_R1_cutadapt.fastq.gz > "$scratch"/"$sample_num"_R1_cutadapt.fastq
gunzip -c "$scratch"/"$sample_num"_R2_cutadapt.fastq.gz > "$scratch"/"$sample_num"_R2_cutadapt.fastq

#Remove low quality reads:
echo "starting printseq-lite"
prinseq-lite -fastq "$scratch"/"$sample_num"_R1_cutadapt.fastq -fastq2 "$scratch"/"$sample_num"_R2_cutadapt.fastq -min_qual_mean 25 -trim_qual_right 20 -min_len 50 -out_good "$scratch"/"$sample_num"_trimmed


##*********************************************************map to reference************************************
echo "Indexing reference sequence using bowtie2"
bwa index "$scratch"/"$REFERENCE" -p "$scratch"/"$REFERENCE"

echo "Mapping reads to reference genome"
bwa mem -t $NSLOTS "$scratch"/"$REFERENCE" "$scratch"/"$sample_num"_trimmed_1.fastq.gz "$scratch"/"$sample_num"_trimmed_2.fastq.gz > "$scratch"/"$sample_num"_reads.sam

echo "Starting samtools - convert SAM to BAM"
samtools view -S -b -o "$scratch"/"$sample_num"_reads.bam "$scratch"/"$sample_num"_reads.sam


# Previously generated samtools index of reference genome.  Generates *.fai file and only need to do 1X.
echo "Indexing Ebo genome with samtools"
samtools faidx "$scratch"/"$REFERENCE"


echo "Starting samtools sort BAM file"
samtools sort -@ $NSLOTS "$scratch"/"$sample_num"_reads.bam -o "$scratch"/"$sample_num"_reads.sorted.bam

echo "Starting samtools index BAM file"
samtools index "$scratch"/"$sample_num"_reads.sorted.bam


JAVA_OPTS='-Xmx50g'
TMP_DIR=/tmp

#Copy only mapped bases, and save:
samtools view -b -F 4 "$scratch"/"$sample_num"_reads.sorted.bam > "$scratch"/"$sample_num"_reads-mapped.sorted.bam

samtools index "$scratch"/"$sample_num"_reads-mapped.sorted.bam

#Make intermediate1 fasta:
echo "Making final fasta!"

echo "Making consensus fasta!"

#Version: 1.3, for almost all sequences.
#samtools mpileup -r 1 -A -aa -d 6000000 -B -Q 0 -f "$scratch"/"$sample_num"_intermediate2_no_contigs.fasta "$scratch"/"$sample_num"_intermediate2-mapped.sorted.bam | /scicomp/home-pure/evk3/setup/ivar-master_1.3/src/ivar consensus -p "$scratch"/"$sample_num".consensus -m 2 -n N

#Version 1.3.1 for 2 sequences with segmentation faults.
samtools mpileup -A -aa -d 6000000 -B -Q 0 -f "$scratch"/"$REFERENCE" "$scratch"/"$sample_num"_reads-mapped.sorted.bam | /scicomp/home-pure/evk3/setup/ivar_1.3.1/src/ivar consensus -p "$scratch"/"$sample_num".consensus -m 2 -n N


#**********************************************************************************************************


#copy results from node /scratch/evk3/ebo back to home dir
cp "$scratch"/"$sample_num"_merge-mapped.sorted.bam "$OUTPUT_PATH"
cp "$scratch"/"$sample_num".consensus.fa "$OUTPUT_PATH"
cp "$scratch"/"$sample_num".consensus.qual.txt "$OUTPUT_PATH"


module unload bwa/0.7.17
module unload samtools/1.9
module unload picard/2.21.1
module unload BEDTools/2.27.1
module unload cutadapt/2.3
module unload prinseq/0.20.3
module unload htslib/1.9
module unload bowtie2/2.3.5.1
module unload gatk/4.1.7.0
module unload htslib/1.10
module unload gcc/9.2.0

echo "Script finish"

