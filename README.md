# MRA_Streptococcus_suis
Repository for the Microbiology Resource Announcements paper on several closed _Streptococcus suis_ genomes

## Introduction
We sequenced 5 _Streptococcus suis_ strains using Nanopore MinION sequencing technology. For these strains, Illumina MiSeq data was already available (see `accessions.txt` for ENA accessions). We assembled complete genomes and characterised these using the Snakemake pipeline provided in this repo.  

## Methods
Snakemake v. 5.7.0 was used to manage the workflow. Please see below for an overview of tools used in which step.

|Process|Tool|
|-----|-----|
|QC and filtering Illumina reads|fastp |
|QC Nanopore reads|FastQC|
|Filtering Nanopore reads|Filtlong|
|Hybrid assembly|Unicycler|
|Assembly QC|Quast|
|MLST calling|mlst|
|Detection resistance genes|ABRicate + NCBI db|
|Detection virulence genes|ABRicate + VFDB db|
|Annotation|Prokka|
|Depth of coverage|Minimap2 + Samtools + BEDtools|

## Results
