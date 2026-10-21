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
include { CAT_CSV as CAT_NANO } from './cat_csv'
include { CAT_CSV as CAT_HEAVY } from './cat_csv'
include { CAT_CSV as CAT_LIGHT } from './cat_csv'

record Sample {
    barcode: String
    heavy_chain: Path
    light_chain: Path?
}

workflow CAT_RIOT {

	// Declare inputs required for the process
    take:
    nanobody: Boolean // True or false flag for nanobody extraction
    files: Channel<Sample>

    // [barcode:barcode01, heavy_chain:./barcode01-1_annot_heavy.csv, light_chain:./barcode01-1_annot_light.csv]

    main:
    // Only cat heavy chain if nanobdy parameter is true
    if (nanobody) {
    // Cat heavy chain outputs per barcode from riot
    heavy_chain_ch = files.flatMap { sample -> sample }
        .map { sample -> tuple(sample.barcode, sample.heavy_chain) }
        .groupBy()
        .map { barcode, file_list -> record(barcode: barcode, files: file_list.toList()) }
    heavy_chain_cat_out = CAT_NANO(heavy_chain_ch)
    } 
    
    // Cat both heavy and light chains
    else {
    // Cat heavy chain outputs per barcode from riot
    heavy_chain_ch = files.flatMap { sample -> sample }
        .map { sample -> tuple(sample.barcode, sample.heavy_chain) }
        .groupBy()
        .map { barcode, file_list -> record(barcode: barcode, files: file_list.toList()) }
    heavy_chain_cat_out = CAT_HEAVY(heavy_chain_ch)

    // Cat light chain outputs per barcode from riot
    light_chain_ch = files.flatMap { sample -> sample }
        .map { sample -> tuple(sample.barcode, sample.light_chain) }
        .groupBy()
        .map { barcode, file_list -> record(barcode: barcode, files: file_list.toList()) }
    light_chain_cat_out = CAT_LIGHT(light_chain_ch)
    }

	// Declare outputs
	emit:
    heavy_chain = heavy_chain_cat_out
    light_chain = light_chain_cat_out
}