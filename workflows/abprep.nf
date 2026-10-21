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
include { MATCHBOX as MATCHBOX_ALL  } from '../modules/local/matchbox'
include { RIOT as RIOT_ALL          } from '../modules/local/riot'
include { MATCHBOX as MATCHBOX_BEST } from '../modules/local/matchbox'
include { RIOT as RIOT_BEST         } from '../modules/local/riot'
include { CAT_FILES                 } from '../modules/local/cat_files'
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

    // Extract heavy and light chain pairs from the reads
    // Match and output all
    matchbox_out_all = MATCHBOX_ALL(
        ch_sample_split,
        matchbox_parameters,
        "all",
        nanobody,
    )

    // Match and output only the best match
    matchbox_out_best = MATCHBOX_BEST(
        ch_sample_split,
        matchbox_parameters,
        "all-best",
        nanobody,
    )

    // Annotate heavy and light chain sequences
    riot_out_best = RIOT_BEST(matchbox_out_best)
    riot_out_all = RIOT_ALL(matchbox_out_all)

    // TODO combine same barcodes together for multiqc?
    // TODO change multiqc to remove XX from barcode_01_XX

    // // Merge files together
    // a = riot_out_best.map {sample -> tuple(sample.barcode, sample.heavy_chain)}.groupBy().map { barcode, bag -> tuple(barcode, bag.toList()) }
    // riot_out_best_cat = CAT_FILES(a)

    // Collect all files for MultiQC report
    ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files
        // .mix(sam_out.stats)
        .mix(sam_stats_out.flatMap { files -> [files.read_lengths, files.stats] })
        .mix(matchbox_out_best.map { files -> files.matchbox_stats })
        .mix(riot_out_best.flatMap { files -> [files.heavy_chain, files.light_chain] })
        .toList()

    // Run Multiqc and AbPreP plugin to generate qc report
    multiqc_out = ABPREP_MULTIQC(
        ch_multiqc_files,
        multiqc_config,
        logo
    )
    
    // // Create counts matrix for downstream analysis
    def ch_riot_cols_keep = file("$projectDir/assets/columns_to_keep.csv", checkIfExists: true)
    riot_files = riot_out_best.flatMap { sample -> [sample.heavy_chain, sample.light_chain] }.toList().view()
    counts_matrix = COUNTS_MATRIX(riot_files, ch_riot_cols_keep)

    emit:
    barcode_file         = ch_sample
    bam_file             = sam_out.aligned_sorted_read
    bam_index            = sam_out.index
    stats                = sam_out.stats
    read_lengths         = sam_out.read_lengths
    matchbox_stats_best  = matchbox_out_best.map { output ->
        output.matchbox_stats
    }
    matchbox_files_best  = matchbox_out_best.map { output ->
        tuple(output.heavy_chain, output.light_chain)
    }
    matchbox_stats_all   = matchbox_out_all.map { output ->
        output.matchbox_stats
    }
    matchbox_files_all   = matchbox_out_all.map { output ->
        tuple(output.heavy_chain, output.light_chain)
    }
    riot_files_best = riot_out_best
    riot_files_all  = riot_out_all
    multiqc_report = multiqc_out
    counts_matrix = counts_matrix
}