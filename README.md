# MRA_Streptococcus_suis
Repository for the Microbiology Resource Announcements paper on several closed _Streptococcus suis_ genomes

## Introduction
We sequenced 5 _Streptococcus suis_ strains using Nanopore MinION sequencing technology. For these strains, Illumina MiSeq data was already available (see `accessions.txt` for ENA accessions). We assembled complete genomes and characterised these using the Snakemake pipeline provided in this repo.

## Methods
Snakemake v. 5.7.1 was used to manage the workflow. Please see below for an overview of tools used in which step.

|Process|Tool|
|-----|-----|
|Downloading Illumina and MinION data|SRA-tools|
|QC and filtering Illumina reads|fastp|
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
Five complete genomes were produced, all consisting of a closed chromosome without any extrachromosomal elements. PhiX data was still present in the Illumina data, which gave a second contig in all assemblies. These have been removed from the assemblies uploaded to the ENA. The accessions of the assemblies in ENA are:

|Strain|Genome accession|
|-----|-----|
|861160|GCA_902702745|
|9401240|GCA_902702775|
|GD-0001|GCA_902702785|
|GD-0088|GCA_902702765|
|S10|GCA_902702755|

The closed genomes were some 40-70kb larger than the short read-only assemblies. We did not identify any regions that were missed in the short read-only assemblies (non-assembling regions?). However, depth of coverage might indicate that several repeats were collapsed in the short read-only assemblies, which caused a difference in size between the hybrid assemblies and the short read-only assemblies.

All data is available from project PRJEB35407.
