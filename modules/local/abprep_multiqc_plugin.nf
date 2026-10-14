/*
Run AbPreP multiqc plugin to generate summary qc report for the pipeline.
*/

// Enable typed processes
nextflow.enable.types = true

process ABPREP_MULTIQC {
	// tag "${barcode}"
    label "process_high"

    // Use Singularity container or pull from Docker container (linux/amd64) if singularity profile is enabled
	container "ghcr.io/leonyqw/abprep-multiqc-plugin:latest"

	// Declare inputs required for the process
    input:
    files: List<Path>
    multiqc_config: Path
    logo: Path

    output:
    file("AbPreP_multiqc_report.html")

    /*
    Run matchbox script, output only heavy and light chain reads, and statistics
    */
    script:
    """
	# Run matchbox script to extract heavy and light chain reads
    multiqc . -c ${multiqc_config}
    """

    stub:
    """
    touch _multiqc_report.html
    """
}