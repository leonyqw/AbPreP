/*
Run AbPreP multiqc plugin to generate summary qc report for the pipeline.
*/

// Enable typed processes
nextflow.enable.types = true

process ABPREP_MULTIQC {
	// tag "${barcode}"
    label "process_high"

    // Use Singularity container or pull from Docker container (linux/amd64) if singularity profile is enabled
	container "ghcr.io/leonyqw/abprep-multiqc-plugin:v0.2.1"

	// Declare inputs required for the process
    input:
    files: List<Path>
    multiqc_config: Path
    logo: Path

    output:
    file("AbPreP_multiqc_report.html")

    /*
    Run multiqc / AbPreP plugin to generate QC report
    */
    script:
    """
    multiqc . -c ${multiqc_config}
    """

    stub:
    """
    touch AbPreP_multiqc_report.html
    """
}