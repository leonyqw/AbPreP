/*
Create a counts matrix for downstream analysis.
*/

// Enable typed processes
nextflow.enable.types = true

process CAT_FILES {
    label "process_medium"

	// Declare inputs required for the process
    input:
    record(
        barcode: String, 
        files: List<Path>
    )

    output:
    // counts_matrix: Path = file("counts_matrix.csv")
    record(
        barcode: barcode,
        file: file("${barcode}_*")
    )
    
    /*
    Run sequence counts R script
    */
    script:
    def suffix = (files[0].name =~ /^barcode\d+-\d+_(.*)/)[0][1]
    """
    awk 'NR==1 || FNR>1' *.csv > ${barcode}_${suffix}
    """
    // if sometihng {
    //     """"""""
    // }
    // else {

    // }

    // stub:
    // """
    // touch .csv
    // """
}