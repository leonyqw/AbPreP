/*
Utilize riot to annotate antibody heavy and light chain DNA sequences.
E.g. provides information on sequence and germline alignment, V(D)J & C sequence and amino acid alignment, and FWR and CDR regions.
*/

//Enable typed processes
nextflow.enable.types = true

process RIOT {
	tag "${barcode}"
    label "process_extreme"

    // Enable conda and install riot if conda profile is set
	conda (params.enable_conda ? 'bioconda::riot-na=4.0.2' : null)

	// Use Singularity container or pull from Docker container for riot-na v4.0.2 (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/biopython_gcc_libxcrypt_python_pruned:96826a8c3e510274' :
    'community.wave.seqera.io/library/biopython_gcc_libxcrypt_python_pruned:c0ab77d048c45319' }"

	// Declare inputs required for the process
    input:
    // Record for sample name, and paths for heavy chain and (if antibody) light chain files
    record (
        barcode: String, 
        heavy_chain: Path, 
        light_chain: Path?
    )
	
	// Declare outputs
	output:
    tuple(
        file("${barcode}_annot_heavy.csv"), 
        file("${barcode}_annot_light.csv", optional: true)
    )

    /*
    Run riot
    -f          Input FASTA file path
    --species   Homo sapiens species germline sequence used
    -p          Set parallel processes used to 16
    -o          Output as annotated files as a csv file
    */
    script:
    // If only nanobody, run riot on heavy chain
    if (params.nanobody) {
    """
    riot_na -f ${heavy_chain} --species VICUGNA_PACOS -p 16 -o "${barcode}_annot_heavy.csv"
    """
    }
    // Otheriwse run riot on antibody sequences for heavy and light chain
    else {
    """
    riot_na -f ${heavy_chain} --species HOMO_SAPIENS -p 16 -o "${barcode}_annot_heavy.csv"
    riot_na -f ${light_chain} --species HOMO_SAPIENS -p 16 -o "${barcode}_annot_light.csv"
    """
    }

    stub:
    """
    touch ${barcode}_annot_heavy.csv
    touch ${barcode}_annot_light.csv
    """
}