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
include { MULTIQC } from 'nf-core/multiqc'

workflow ABPREP {

    take:
    read_dir: String
    sample_sheet: String
    phagemid_ref: Path
    matchbox_script: Path
    matchbox_parameters: Path
    nanobody: Boolean

    main:

    ch_sample = PARSE_SAMPLE_SHEET(read_dir, sample_sheet)

    // QC: Identify % aligning to the reference (gDNA/helper phage contamination)
    minimap_out = MINIMAP2(ch_sample, phagemid_ref)

    // Convert and index the SAM file format to BAM file format
    sam_out = SAMTOOLS(minimap_out)

    // Extract heavy and light chain pairs from the reads
    // Match and output all
    matchbox_out_all = MATCHBOX_ALL(
        ch_sample,
        matchbox_script,
        matchbox_parameters,
        "all",
        nanobody,
    )

    // Match and output only the best match
    matchbox_out_best = MATCHBOX_BEST(
        ch_sample,
        matchbox_script,
        matchbox_parameters,
        "all-best",
        nanobody,
    )

    // Annotate heavy and light chain sequences
    riot_out_best = RIOT_BEST(matchbox_out_best)
    riot_out_all = RIOT_ALL(matchbox_out_all)

    // Run multiqc to generate summary qc report
    // MULTIQC("/results")

    emit:
    barcode_file         = ch_sample
    bam_file             = sam_out.aligned_sorted_read
    bam_index            = sam_out.index
    flagstat             = sam_out.flagstat
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
}