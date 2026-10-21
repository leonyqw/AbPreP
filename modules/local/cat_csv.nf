/*
Process to concatenate CSV files together.
*/

// Enable typed processes
nextflow.enable.types = true

process CAT_CSV {
    label "process_medium"

	// Declare inputs required for the process
    input:
    record(
        barcode: String, 
        files: List<Path>
    )

    output:
    record(
        barcode: barcode,
        file: file("${barcode}_*")
    )
    
    /*
    Run script to cat files together
    */
    script:
    // Get file suffix name after the barcode
    def suffix = (files[0].name =~ /^barcode\d+-\d+_(.*)/)[0][1]
    """
    awk 'NR==1 || FNR>1' *.csv > ${barcode}_${suffix}
    """
}