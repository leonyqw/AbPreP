# AbPreP - Antibody preprocessing pipeline
This nextflow pipeline is designed to assist in processing of antibody long-read sequences. This will align and annotate heavy and light chains from long reads, and provide QC metrics.

## Useful links
* The [documentation website]()
* The [data]()


## Introduction
[Insert ]

## Usage
First, prepare samplesheet with input data as follow:
```
sample,xx,xx
sample1,xx,xx
```

```
nextflow run main.nf \
	-profile <conda/singularity/.../institute>
	-params-file <path to parameter file>
	--read_dir <path to fastq files> \
	--sample_sheet <path to sample sheet> \
	--phagemid_ref <path to reference genome> \
	--matchbox_script <path to matchbox script>
```

Parameters
Input/output options
```
```

Reference genome options
```
```

Generic options
```
--help              	: prints this help message
```
```
Required parameters:
--read_dir				: Specify full path to the read file(s) location
--sample_sheet  		: Specify full path to the .csv sample sheet
--phagemid_ref			: Specify full path to the reference genome
--matchbox_script		: Specify full path to the matchbox script
--matchbox_parameters	: Specify full path to the parameters file for the matchbox script

Optional parameters:
--nanobody              : Takes a true or false value. Specifies whether pipeline is for nanobody (true) or antibody (false) sequencing data (default: false)
--output_dir        	: Specify the full path to where the output files will be written  (default: "$projectDir/results)
-profile		    	: Specify the profile to run nextflow through
						  Options - [standard, wehi, conda, singularity, local] (default: standard)
```

## Input
This pipeline requires as input:
* The path of the directory containing the basecalled and demultiplexed nanopore long reads
    - Expects a directory containing all fastq files containing a barcode number within the file names (e.g. 1034_barcode1.fastq)
* The sample sheet with the format [barcode, sample_name, species]
* The reference genome to be used in fa format
* The matchbox script to split the read into heavy and light chains
* The path of the directory where it should write the results

## Output
This pipeline will produce QC metrics and the annotation results for paired heavy and light chain sequences from all samples. All aligned sequences in BAM format, heavy and light chain sequences in FASTA format, as well as intermediate files (samtools QC results, matchbox stats) are written to the results directory.
