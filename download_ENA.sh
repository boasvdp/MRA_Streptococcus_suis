#!/bin/bash

cd /home/boas/experiments/MRA_Streptococcus_suis

mkdir -p raw_illumina

awk 'NR > 1 {print $2}' accessions.txt > list
$HOME/tools/getSeqENA/getSeqENA.py -l list -o raw_illumina/

awk 'NR>1 {print $0}' accessions.txt | while read sample acc
do
	mv raw_illumina/${acc}/${acc}_1.fq.gz raw_illumina/${sample}_1.fastq.gz
	mv raw_illumina/${acc}/${acc}_2.fq.gz raw_illumina/${sample}_2.fastq.gz
	rm -r raw_illumina/${acc}
done

rm raw_illumina/getSeqENA.report.txt raw_illumina/run*log list
