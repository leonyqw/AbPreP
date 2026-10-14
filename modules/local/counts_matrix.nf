/*
Create a counts matrix for downstream analysis.
*/

// Enable typed processes
nextflow.enable.types = true

process COUNTS_MATRIX {
    label "process_medium"

	// Declare inputs required for the process
    input:
    // Record for sample name, and path for DNA sequence fastq files
    files: List<Path>

    output:
    // counts_matrix: Path = file("counts_matrix.csv")
    file("counts_matrix.csv")

    /*
    Run sequence counts R script
    */
    script:
    """
    Rscript create_sequence_table.r
    """

    stub:
    """
    touch counts_matrix.csv
    """
}