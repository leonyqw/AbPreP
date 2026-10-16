/*
Create a counts matrix for downstream analysis.
*/

// Enable typed processes
nextflow.enable.types = true

process COUNTS_MATRIX {
    label "process_medium"

    // Enable conda and install R packages if conda profile is set
	conda (params.enable_conda ? "conda-forge::r-readr conda-forge::r-tidyr conda-forge::r-dplyr conda-forge::r-stringr conda-forge::r-optparse conda-forge::r-fs" : null)

	// Use Singularity container or pull from Docker container for R packages (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/r-dplyr_r-fs_r-optparse_r-readr_pruned:a6c03440de4f8e4e' :
    'community.wave.seqera.io/library/r-dplyr_r-fs_r-optparse_r-readr_pruned:f3ad5e8b62e1f233' }"

	// Declare inputs required for the process
    input:
    files: List<Path>
    columns_to_keep: Path

    stage:
    stageAs files, "data/*" 

    output:
    // counts_matrix: Path = file("counts_matrix.csv")
    file("counts_matrix.csv")

    /*
    Run sequence counts R script
    */
    script:
    """
    create_sequence_table.r --input ./data --keep_cols ${columns_to_keep}
    """

    stub:
    """
    touch counts_matrix.csv
    """
}