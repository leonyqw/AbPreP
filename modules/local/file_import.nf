/*
Import samples using a sample sheet
*/

// Enable typed processes
nextflow.enable.types = true

// ADAPTED FROM https://stackoverflow.com/questions/74039553/nextflow-rename-barcodes-and-concatenate-reads-within-barcodes

process CONCAT_READS {
    tag "${barcode}"

    input:
    // Record for sample barcode, and list of files with the barcode
    record(
        barcode: String, 
        files: List<Path>
    )

    // Output sample: tuple containing barcode and merged file
    output:
    record(
        barcode: barcode, 
        file: file("${barcode}_merged.fastq")
    )

    script:
    // Check if all files are the same format, or if files are not found
    if( files.size() == 0 ) {
        error "No files found for ${barcode}"
        }
    // Append and join together files from the same barcode, and output a merged file
    """
    zcat -f ${files.join(' ')} > "${barcode}_merged.fastq"
    """

    stub:
    """
    touch ${barcode}_merged.fastq
    """
}

workflow PARSE_SAMPLE_SHEET {
    
    take:
    read_dir: String // Directory where reads are stored
    sample_sheet: String // Path to sample sheet
    
    main:

    // Parse list of barcodes in the sample sheet
    barcodes = channel.fromPath(sample_sheet)
    .splitCsv(header: true)
    .map { row -> row.barcode }

    // Get list of files for each barcode from the read directory, as well as any files in subdirectories that match
    barcode_files = barcodes
    .map { barcode ->
        record(
            barcode: barcode, 
            files: files("${read_dir}/**${barcode}*.{fastq,fq,fastq.gz,fq.gz}")
        )
    }

    // Read and concat (if multiple files) into one file per sample / barcode
    sample = CONCAT_READS(barcode_files)
    // CONCAT_READS(barcode_files)

	// Declare outputs
    emit:
    // sample: Channel<Sample> = sample
    sample
}

// record Sample {
//         barcode: String
//         file: Path
// }