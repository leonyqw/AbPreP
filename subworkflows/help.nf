#!/usr/bin/env nextflow

//Enable typed processes
nextflow.enable.types = true

// Print help message information
workflow helpMessage {

    if ( params.help ) {
        log.info"""
Typical pipeline command: 

nextflow run main.nf --read_dir <path to fastq files> \\
    --sample_sheet <path to sample sheet> \\
	--phagemid_ref <path to reference genome> \\
    --matchbox_script <path to matchbox script>

Required Arguments:
--read_dir		: Specify full path to the read file(s) location
--sample_sheet          : Specify full path to the .csv sample sheet (format: barcode01, sample_x, rat)
--phagemid_ref		: Specify full path to the reference genome
--matchbox_script	: Specify full path to matchbox script
--matchbox_parameters	: Specify full path to parameters file for matchbox script

Optional Arguments:
--nanobody              : Takes a true or false value. Specifies whether pipeline is for nanobody (true) or antibody (false) sequencing data (default: false)
--output_dir		: Specify the full path to where the output files will be written (default: "$projectDir/results")
-profile		: Specify the profile to run nextflow through
			  Options - [standard, wehi, conda, singularity, local] (default: standard)
""".stripIndent()
    
    exit(1,"")
    }
}

// Input/output options
//   --input                       [string]           Path to a metadata file containing information about the samples in the experiment.
//   --outdir                      [string]           The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure.
//   --email                       [string]           Email address for completion summary.
//   --multiqc_title               [string]           MultiQC report title. Printed as page header, used for filename if not otherwise specified.

// Reference genome options
//   --genome                      [string]           Name of iGenomes reference.
//   --fasta                       [string]           Path to FASTA genome file.

// Process skipping options
//   --skip_trim                   [boolean]          Skip trimming fastq files with seqtk

// Generic options
//   --multiqc_methods_description [string]           Custom MultiQC yaml file containing HTML including a methods description.
//   --help                        [boolean, string]  Display the help message.
//   --help_full                   [boolean]          Display the full detailed help message.
//   --show_hidden                 [boolean]          Display hidden parameters in the help message (only works when --help or --help_full are provided).
