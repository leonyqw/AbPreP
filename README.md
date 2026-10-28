# AbPreP - Antibody preprocessing pipeline
AbPreP is a bioinformatic nextflow pipeline designed to assist in preprocessing antibody long-read sequences. It takes a sample sheet of FASTQ/FASTA files as input, aligns reads to a reference genome, extracts and annotates heavy and light chains, produces a counts matrix and an extensive QC report. This pipeline can also be extended and utilized for nanobody data.

[Insert metro map]

## Useful links
* The [documentation website]()
* The [data]()

## Usage
First, prepare samplesheet with input data as follow:

**samplesheet.csv**:
```csv
barcode,sample_name,species
barcode01,SAMPLE1,human
```
Each row represents a different fastq file or directory for that barcoded sample. 	

Now, you can run the pipeline using:
```bash
nextflow run main.nf \
	--read_dir <READS> \
	--sample_sheet <SAMPLE SHEET> \
	--phagemid_ref <REFERENCE GENOME> \
	--matchbox_script <MATCHBOX SCRIPT> 
	--params-file <MATCHBOX PARAMETERS> \
	--multiqc_config <MULTIQC CONFIG> \
	-profile <conda/singularity/.../institute>
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
--read_dir		: Specify full path to the read file(s) location
--sample_sheet  	: Specify full path to the .csv sample sheet
--phagemid_ref		: Specify full path to the reference genome
--matchbox_script	: Specify full path to the matchbox script
--matchbox_parameters	: Specify full path to the parameters file for the matchbox script
--multiqc_config	: Specify full path to the MultiQC config YAML file

Optional parameters:
--nanobody              : Takes a true or false value. Specifies whether pipeline is for nanobody (true) or antibody (false) sequencing data (default: false)
--num_reads		: Number of reads to split the input files into
--output_dir        	: Specify the full path to where the output files will be written  (default: "$projectDir/results)
-profile		: Specify the profile to run nextflow through
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
This pipeline will produce:
* csv file of extracted and annotated heavy and light chains per barcode
* QC report
* Counts matrix of each productive heavy and light chain pair

All intermediate files are written to the results directory.
