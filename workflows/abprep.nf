#!/usr/bin/env nextflow

// Enable typed processes
nextflow.enable.types = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PARSE_SAMPLE_SHEET        } from '../modules/local/file_import'
include { MINIMAP2                  } from '../modules/local/minimap2'
include { SAMTOOLS                  } from '../modules/local/samtools'
include { SAMTOOLS_STATS              } from '../modules/local/samtools'
include { MATCHBOX as MATCHBOX_ALL  } from '../modules/local/matchbox'
include { RIOT as RIOT_ALL          } from '../modules/local/riot'
include { MATCHBOX as MATCHBOX_BEST } from '../modules/local/matchbox'
include { RIOT as RIOT_BEST         } from '../modules/local/riot'
include { CAT_CSV as CAT_MATCHBOX_STATS_1   } from '../modules/local/cat_csv'
include { CAT_CSV as CAT_MATCHBOX_STATS_2   } from '../modules/local/cat_csv'
include { CAT_RIOT as CAT_RIOT_1  } from '../modules/local/cat_riot'
include { CAT_RIOT as CAT_RIOT_2  } from '../modules/local/cat_riot'
include { ABPREP_MULTIQC            } from '../modules/local/abprep_multiqc_plugin'
include { COUNTS_MATRIX             } from '../modules/local/counts_matrix'

workflow ABPREP {

    take:
    read_dir: String
    sample_sheet: String
    phagemid_ref: Path
    matchbox_parameters: Path
    nanobody: Boolean
    multiqc_config: Path
    logo: Path
    num_reads: Integer

    main:
    // Parse samplesheet and get samples
    ch_sample = PARSE_SAMPLE_SHEET(read_dir, sample_sheet)

    // Create channel of split fastq files for each sample
    ch_sample_split = ch_sample.flatMap { sample ->
        sample.file
        .splitFastq( by: num_reads, file: true )
        .withIndex(1)
        .collect { split_file, index ->
                record(
                    barcode: sample.barcode,
                    file_num: index,
                    file: split_file
                )
            }
    }

    // QC: Identify % aligning to the reference (gDNA/helper phage contamination)
    minimap_out = MINIMAP2(ch_sample_split, phagemid_ref)

    // Convert and index the SAM file format to BAM file format
    sam_out = SAMTOOLS(minimap_out)
    sam_merged_ch = sam_out.map {sample -> tuple(sample.barcode, sample.aligned_sorted_read)}
        .groupBy()
        .map { barcode, bag -> record(barcode: barcode, files: bag.toList()) }
    // Merge split sample files together and get stats
    sam_stats_out = SAMTOOLS_STATS(sam_merged_ch)

    // Extract heavy and light chain pairs from the reads
    // Match and output all
    matchbox_out_all = MATCHBOX_ALL(
        ch_sample_split,
        matchbox_parameters,
        "all",
        nanobody,
    )
    // Group matchbox counts stats per sample and cat stats together
    matchbox_stats_all_ch = matchbox_out_all.map {sample -> tuple(sample.barcode, sample.matchbox_stats)}
        .groupBy()
        .map { barcode, bag -> record(barcode: barcode, files: bag.toList()) }
    matchbox_stats_all_cat_out = CAT_MATCHBOX_STATS_1(matchbox_stats_all_ch)

    // Match and output only the best match
    matchbox_out_best = MATCHBOX_BEST(
        ch_sample_split,
        matchbox_parameters,
        "all-best",
        nanobody,
    )
    // Group matchbox counts stats per sample and cat stats together
    matchbox_stats_best_ch = matchbox_out_best.map {sample -> tuple(sample.barcode, sample.matchbox_stats)}
        .groupBy()
        .map { barcode, bag -> record(barcode: barcode, files: bag.toList()) }
    matchbox_stats_best_cat_out = CAT_MATCHBOX_STATS_2(matchbox_stats_best_ch)

    // Annotate heavy and light chain sequences
    riot_all_out = RIOT_ALL(matchbox_out_all)
    riot_best_out = RIOT_BEST(matchbox_out_best)

    // Concatenate heavy (and light chains) per barcode from riot outputs
    riot_all_cat_out = CAT_RIOT_1(nanobody, riot_all_out.collect())
    riot_best_cat_out = CAT_RIOT_2(nanobody, riot_best_out.collect())

    // TODO combine same barcodes together for multiqc?
    // TODO Count lines? countfastq, if greater than number, don't go othrough split
    // TODO OR, create separate process in samtools to aggregate / do the output for each combined output for stats and read length
    // TODO in matchbox, riot, read length modules, reformat so reads in barcodes, but then join same barcodes together for multiqc and counts matrix. Append to each dict if it's same key
    // TODO combine riot and matchbox outputs in multiqc?

    // Collect all files for MultiQC report
    ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files
        .mix(sam_stats_out.flatMap { files -> [files.read_lengths, files.stats] })
        .mix(matchbox_stats_best_cat_out.map { files -> files.file })
        .mix(riot_best_cat_out.heavy_chain.map { chain -> chain.file })
        .mix(riot_best_cat_out.light_chain.map { chain -> chain.file })
        .toList()

    // Run Multiqc and AbPreP plugin to generate qc report
    multiqc_out = ABPREP_MULTIQC(
        ch_multiqc_files,
        multiqc_config,
        logo
    )
    
    // TODO replace with concatenated file?
    // Create counts matrix for downstream analysis
    def ch_riot_cols_keep = file("$projectDir/assets/columns_to_keep.csv", checkIfExists: true)
    riot_files = riot_best_out.flatMap { sample -> [sample.heavy_chain, sample.light_chain] }.toList()
    counts_matrix = COUNTS_MATRIX(riot_files, ch_riot_cols_keep)

    emit:
    barcode_file         = ch_sample
    bam_file             = sam_out.map {
        output -> output.aligned_sorted_read
    }
    bam_index            = sam_out.map {
        output -> output.index
    }
    stats                = sam_stats_out.map {
        output -> output.stats
    }
    read_lengths         = sam_stats_out.map {
        output -> output.read_lengths
    }
    matchbox_stats_best  = matchbox_stats_best_cat_out.map {
        output -> output.file
    }
    matchbox_files_best  = matchbox_out_best.map {
        output -> tuple(output.heavy_chain, output.light_chain)
    }
    matchbox_stats_all   = matchbox_stats_all_cat_out.map { 
        output -> output.file
    }
    matchbox_files_all   = matchbox_out_all.map { 
        output -> tuple(output.heavy_chain, output.light_chain)
    }
    riot_files_best = riot_best_cat_out.heavy_chain.map { chain -> chain.file }.mix(riot_best_cat_out.light_chain.map { chain -> chain.file })
    riot_files_all  = riot_all_cat_out.heavy_chain.map { chain -> chain.file }.mix(riot_all_cat_out.light_chain.map { chain -> chain.file })
    multiqc_report = multiqc_out
    counts_matrix = counts_matrix
}