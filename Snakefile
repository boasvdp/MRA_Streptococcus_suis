configfile: "config.yaml"

IDS = []

with open("accessions.txt", "r") as file:
  lines = file.readlines()

for line in lines[1:]:
  sample = line.split('\t')[0]
  IDS.append(sample)

rule all:
	input:
		expand("fastqc_out/{sample}", sample = IDS),
		expand("quast_out/{sample}", sample = IDS),
		expand("mlst/{sample}.tsv", sample = IDS),
		expand("coverage_out/illumina/{sample}.txt", sample = IDS),
		expand("coverage_out/nanopore/{sample}.txt", sample = IDS),
		expand("abricate_out/ncbi/{sample}.tsv", sample = IDS),
		expand("abricate_out/vfdb/{sample}.tsv", sample = IDS),
		expand("prokka_out/{sample}", sample = IDS),
		expand("gc_out/{sample}.txt", sample = IDS)

rule sratools:
	input:
		"accessions.txt"
	output:
		fw = expand("raw_illumina/{sample}_1.fastq.gz", sample=IDS),
		rv = expand("raw_illumina/{sample}_2.fastq.gz", sample=IDS),
		long = expand("raw_nanopore/{sample}.fastq.gz", sample=IDS)
	conda:
		"envs/sratools.yaml"
	log:
		"logs/sratools.log"
	shell:
		"""
		bash scripts/download_data.sh {input}
		"""

rule fastp:
	input:
		fw = "raw_illumina/{sample}_1.fastq.gz",
		rv = "raw_illumina/{sample}_2.fastq.gz"
	output:
		fw = "trimmed_illumina/{sample}_ATQT_1.fastq.gz",
		rv = "trimmed_illumina/{sample}_ATQT_2.fastq.gz",
		json = "fastp_out/{sample}_fastp.json",
		html = "fastp_out/{sample}_fastp.html"
	conda:
		"envs/fastp.yaml"
	params:
		general = config["fastp"]["general"],
		compression_level = config["fastp"]["compression_level"]
	log:	
		"logs/fastp/fastp_{sample}.log"
	threads: 6
	shell:
		"""
		fastp -w {threads} -z {params.compression_level} -i {input.fw} -o {output.fw} -I {input.rv} -O {output.rv} {params.general} --html {output.html} --json {output.json} 2>&1>{log}
		"""

rule filtlong:
	input:
		nanopore = "raw_nanopore/{sample}.fastq.gz",
		fw = "trimmed_illumina/{sample}_ATQT_1.fastq.gz",
		rv = "trimmed_illumina/{sample}_ATQT_2.fastq.gz"
	output:
		"trimmed_nanopore/{sample}.fastq.gz"
	conda:
		"envs/filtlong.yaml"
	params:
		target_bases = config["filtlong"]["target_bases"],
		keep_percent = config["filtlong"]["keep_percent"]
	log:
		"logs/filtlong/{sample}.log"
	shell:
		"""
		filtlong --target_bases {params.target_bases} --illumina_1 {input.fw} --illumina_2 {input.rv} --trim {input.nanopore} | gzip > {output} 2>{log}
		"""

rule fastqc:
	input:
		nanopore = "raw_nanopore/{sample}.fastq.gz"
	output:
		directory("fastqc_out/{sample}")
	conda:
		"envs/fastqc.yaml"
	log:
		"logs/fastqc/{sample}.log"
	threads: 6
	shell:
		"""
		mkdir -p {output}
		fastqc -t {threads} --outdir {output} {input} 2>&1>{log}
		"""

rule unicycler:
	input:
		nanopore = "trimmed_nanopore/{sample}.fastq.gz",
		fw = "trimmed_illumina/{sample}_ATQT_1.fastq.gz",
		rv = "trimmed_illumina/{sample}_ATQT_2.fastq.gz"
	output:
		"unicycler_out/{sample}/assembly.fasta"
	conda:
		"envs/unicycler.yaml"
	params:
		outdir = "unicycler_out/{sample}"
	log:
		"logs/unicycler/{sample}.log"
	threads: 6
	shell:
		"""
		unicycler -1 {input.fw} -2 {input.rv} --long {input.nanopore} -o {params.outdir} --threads {threads}
		"""

rule quast:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		directory("quast_out/{sample}")
	conda:
		"envs/quast.yaml"
	log:
		"logs/quast/quast_{sample}.log"
	shell:
		"""
		quast -o {output} {input.assembly}
		"""

rule mlst:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		mlst = "mlst/{sample}.tsv"
	conda:
		"envs/mlst.yaml"
	log:
		"logs/mlst/mlst_{sample}.log"
	shell:
		"""
		mlst {input.assembly} 1> {output.mlst} 2>{log}
		"""

rule abricate_ncbi:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		"abricate_out/ncbi/{sample}.tsv"
	conda:
		"envs/abricate.yaml"
	params:
		minid = config["abricate_ncbi"]["minid"],
		mincov = config["abricate_ncbi"]["mincov"],
		db = config["abricate_ncbi"]["db"]
	log:
		"logs/abricate_ncbi/abricate_{sample}.log"
	shell:
		"""
		abricate --db {params.db} --mincov {params.mincov} --minid {params.minid} {input.assembly} 1> {output} 2>{log}
		"""

rule abricate_vfdb:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		"abricate_out/vfdb/{sample}.tsv"
	conda:
		"envs/abricate.yaml"
	params:
		minid = config["abricate_vfdb"]["minid"],
		mincov = config["abricate_vfdb"]["mincov"],
		db = config["abricate_vfdb"]["db"]
	log:
		"logs/abricate_vfdb/abricate_{sample}.log"
	shell:
		"""
		abricate --db {params.db} --mincov {params.mincov} --minid {params.minid} {input.assembly} 1> {output} 2>{log}
		"""

rule prokka:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		directory("prokka_out/{sample}")
	conda:
		"envs/prokka.yaml"
	params:
		general = config["prokka"]["general"],
		kingdom = config["prokka"]["kingdom"],
		genus = config["prokka"]["genus"],
		species = config["prokka"]["species"],
		prefix = "{sample}"
	log:
		spades = "logs/prokka/{sample}.log"
	threads: 6
	shell:
		"""
		prokka {params.general} --force --compliant --centre XXX --outdir {output} --genus {params.genus} --species {params.species} --kingdom {params.kingdom} --cpus {threads} --prefix {params.prefix} {input.assembly} 2>&1>{log}
		if [ -f {output}/*.gff ]; then echo "{output} exists"; else exit 1; fi
		"""

rule coverage_illumina:
	input:
		fw = "trimmed_illumina/{sample}_ATQT_1.fastq.gz",
		rv = "trimmed_illumina/{sample}_ATQT_2.fastq.gz",
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		"coverage_out/illumina/{sample}.txt"
	conda:
		"envs/coverage.yaml"
	params:
		minimap_x = config["coverage_illumina"]["minimap_x"]
	log:
		"logs/coverage_illumina/{sample}.log"
	threads: 6
	shell:
		"""
		minimap2 -a -x {params.minimap_x} -t {threads} {input.assembly} {input.fw} {input.rv} | samtools sort -l 0 --threads {threads} | bedtools genomecov -d -ibam stdin | awk '{{t += $3}} END {{print t/NR}}' 1>{output} 2>{log}
		"""

rule coverage_nanopore:
	input:
		reads = "trimmed_nanopore/{sample}.fastq.gz",
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		"coverage_out/nanopore/{sample}.txt"
	conda:
		"envs/coverage.yaml"
	params:
		minimap_x = config["coverage_nanopore"]["minimap_x"]
	log:
		"logs/coverage_nanopore/{sample}.log"
	threads: 6
	shell:
		"""
		minimap2 -a -x {params.minimap_x} -t {threads} {input.assembly} {input.reads} | samtools sort -l 0 --threads {threads} | bedtools genomecov -d -ibam stdin | awk '{{t += $3}} END {{print t/NR}}' 1>{output} 2>{log}
		"""

rule gc:
	input:
		assembly = "unicycler_out/{sample}/assembly.fasta"
	output:
		"gc_out/{sample}.txt"
	conda:
		"envs/seqtk.yaml"
	log:
		"logs/gc/{sample}.log"
	shell:
		"""
		bash scripts/get_gc.sh {input} > {output} 2>{log}
		"""
