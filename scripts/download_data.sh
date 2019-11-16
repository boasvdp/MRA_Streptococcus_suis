#!/bin/bash

if [ -f $1 ]
then
	echo "Using $1 to get accession numbers"
else
	echo "Cannot access $1. Exiting..."
	exit 1
fi

NCOLS=$(awk '{print NF}' $1 | sort | uniq)

if [[ "$NCOLS" -eq 3 ]]
then
	echo "$1 contains three columns. Continuing..."
else
	echo "Please check if all rows of $1 contain three columns. Exiting..."
	exit 1
fi

echo "Will try to download data for $(($(wc -l $1 | awk '{print $1}') - 1)) samples"

awk 'NR>1 {print $0}' $1 | while read isolate illumina nanopore
do
	fasterq-dump ${illumina} --skip-technical -O raw_illumina
	mv raw_illumina/${illumina}_1.fastq raw_illumina/${isolate}_1.fastq
	mv raw_illumina/${illumina}_2.fastq raw_illumina/${isolate}_2.fastq
	gzip raw_illumina/${isolate}_1.fastq raw_illumina/${isolate}_2.fastq
	fasterq-dump ${nanopore} --skip-technical -O raw_nanopore
	mv raw_nanopore/${nanopore}.fastq raw_nanopore/${isolate}.fastq
	gzip raw_nanopore/${isolate}.fastq
done
