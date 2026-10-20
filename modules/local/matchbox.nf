/*
Utilize matchbox to extract only the variable heavy and light chains.
*/

// Enable typed processes
nextflow.enable.types = true

// Create record type for sample
record Sample {
    barcode: String
    file_num: Integer
    file: Path
}

record MatchboxOutput {
    barcode: String
    matchbox_stats: Path
    heavy_chain: Path
    light_chain: Path?
}

process RUN_MATCHBOX {
	tag "${barcode}, file:${file_num}"
    label "process_high"

    // Use Singularity container or pull from Docker container if singularity profile is enabled
	container 'ghcr.io/jakob-schuster/matchbox@sha256:774786ff07c5d9d16d1fb64d8329c9c2cf9fd0fe3d89856e2a2672133e0c3fae'

	// Declare inputs required for the process
    input:
    // Record for sample name, and path for DNA sequence fastq files
	record (
        barcode: String, 
        file_num: Integer,
        file: Path
    )
    matchbox_script: Path // Path to matchbox script
    matchbox_parameters: Map // Map of parameters for matchbox script
    match_param: String // Matchbox script matching argument
    nanobody: Boolean // Matchbox parameter for extracting nanobody instead of antibody sequences

    output:
    record(
        barcode: barcode,
        file_num: file_num,
        matchbox_stats: file("${barcode}_${file_num}_matchbox_counts.csv"), 
        heavy_chain: file("${barcode}_${file_num}_heavy.fasta"), 
        light_chain: file("${barcode}_${file_num}_light.fasta", optional: true)
    )

    /*
    Run matchbox script, output only heavy and light chain reads, and statistics
    -s  Execute the matchbox script
    -e  Include error tolerance of 0.3 (30%) for insertions, deletions and substitutions
    -a  Set seqid argument as the sample name, along with target sequences for extraction of light and heavy chains from matchbox parameter csv file
    --with-reverse-complement   Also process the reverse complement of the reads over the script
    -m  Select the match parameter (all, all-best, one-best)
    */
    script:
    """
	# Run matchbox script to extract heavy and light chain reads
    matchbox \\
    -s ${matchbox_script} -e 0.3 \\
    -a "seqid='${barcode}_${file_num}', LCss = ${matchbox_parameters.LCss}, LC_after_lambda = ${matchbox_parameters.LC_after_lambda}, LC_after_kappa = ${matchbox_parameters.LC_after_kappa}, HCss = ${matchbox_parameters.HCss}, HC_after = ${matchbox_parameters.HC_after}, nanobody_ss = ${matchbox_parameters.nanobody_ss}, nanobody_after = ${matchbox_parameters.nanobody_after}, nanobody = ${nanobody}" \\
    --with-reverse-complement \\
    -m ${match_param} \\
    ${file}

    # Divide the total number of reads by 2 (currently matchbox totals include both forward and reverse reads)
    awk -F',' 'BEGIN{OFS=","} \$1=="total reads"{\$2=\$2/2} {print}' ${barcode}_${file_num}_matchbox_counts.csv > tmp.csv && mv tmp.csv ${barcode}_${file_num}_matchbox_counts.csv
    """

    stub:
    """
    touch ${barcode}_${file_num}_matchbox_counts.csv
    touch ${barcode}_${file_num}_heavy.fasta
    touch ${barcode}_${file_num}_light.fasta
    """
}

workflow MATCHBOX {

	// Declare inputs required for the process
    take:
    sample: Sample
    matchbox_parameters: Path // Path to matchbox parameters
    match_param: String // Matchbox script matching argument
    nanobody: Boolean // True or false flag for nanobody extraction

    main:
    // Parse parameters file
    parameters = file(matchbox_parameters)
    .splitCsv( header: true )
    .collectEntries { row -> [(row.Parameter): row.Value] }

    // param = channel.fromPath("${matchbox_parameters}")
    // .flatMap { csv -> csv.splitCsv(header: true, sep: ',') }
    // .map { row -> [(row.Parameter): row.Value] }
    // .reduce { 
    //     param1, param2 -> param1 + param2
    // }
    // .view()

    // Run matchbox process
    matchbox_out = RUN_MATCHBOX(sample, 
        file("${projectDir}/bin/matchbox_preprocessing_script.mb"), 
        parameters, match_param, nanobody)

	// Declare outputs
	emit:
    matchbox_out
}