/*
Utilize matchbox to extract only the variable heavy and light chains.
*/

// Enable typed processes
nextflow.enable.types = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { CAT_CSV as CAT_HEAVY } from './cat_csv'
include { CAT_CSV as CAT_LIGHT } from './cat_csv'

record Sample {
    barcode: String
    heavy_chain: Path
    light_chain: Path?
}

record Chain {
    barcode: String
    file: Path
}

workflow CAT_RIOT {

	// Declare inputs required for the process
    take:
    nanobody: Boolean // True or false flag for nanobody extraction
    files: Channel<Sample>

    main:
    def light_chain_cat_out = null

    // Cat heavy chain outputs per barcode from riot
    heavy_chain_ch = files.flatMap { sample -> sample }
        .map { sample -> tuple(sample.barcode, sample.heavy_chain) }
        .groupBy()
        .map { barcode, file_list -> record(barcode: barcode, files: file_list.toList()) }
    heavy_chain_cat_out = CAT_HEAVY(heavy_chain_ch)

    // Only cat light chain if nanobdy parameter is false
    if (!nanobody) {
        // Cat light chain outputs per barcode from riot
        light_chain_ch = files.flatMap { sample -> sample }
            .map { sample -> tuple(sample.barcode, sample.light_chain) }
            .groupBy()
            .map { barcode, file_list -> record(barcode: barcode, files: file_list.toList()) }
        light_chain_cat_out = CAT_LIGHT(light_chain_ch)
    }

	emit:
    heavy_chain = heavy_chain_cat_out
    light_chain = light_chain_cat_out
}