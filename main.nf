#!/usr/bin/env nextflow

// Enable typed processes
nextflow.enable.types = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { header             } from './subworkflows/header'
include { helpMessage        } from './subworkflows/help'
include { validateParameters ; paramsSummaryLog ; samplesheetToList } from 'plugin/nf-schema'
include { ABPREP             } from './workflows/abprep'
// include { PARSE_SAMPLE_SHEET        } from './modules/local/file_import'
// include { MINIMAP2                  } from './modules/local/minimap2'
// include { SAMTOOLS                  } from './modules/local/samtools'
// include { MATCHBOX as MATCHBOX_ALL  } from './modules/local/matchbox'
// include { RIOT as RIOT_ALL          } from './modules/local/riot'
// include { MATCHBOX as MATCHBOX_BEST } from './modules/local/matchbox'
// include { RIOT as RIOT_BEST         } from './modules/local/riot'

// Pipeline parameters
params {
    read_dir: String
    sample_sheet: String
    phagemid_ref: Path
    matchbox_script: Path
    matchbox_parameters: Path
    help: Boolean
    enable_conda: Boolean
    nanobody: Boolean
}

workflow {

    main:

    // Validate correct nextflow version is used
    if (!nextflow.version.matches('>=26.04.0')) {
        error("This workflow requires Nextflow version 26.04 or greater -- You are running version ${nextflow.version}")
    }

    // Print message for conda which is currently unsupported
    if (params.enable_conda) {
        error("Note: The use of conda is currently unsupported")
    }

    // Invoke help message if required
    helpMessage()

    // Print pipeline information
    header()

    // Validate parameters
    // paths_to_validate = [params.read_dir, params.phagemid_ref, params.matchbox_script, params.matchbox_parameters].join(",")
    // VALIDATE_PARAMS(paths_to_validate)

    // Validate input parameters
    validateParameters()

    // Print summary of supplied parameters
    log.info(paramsSummaryLog(workflow))

    // Create a new channel of metadata from a sample sheet passed to the pipeline through the --input parameter
    // ch_input = Channel.fromList(samplesheetToList(params.sample_sheet, "assets/schema_input.json"))

    // Run AbPreP workflow
    abprep = ABPREP(
        params.read_dir,
        params.sample_sheet,
        params.phagemid_ref,
        params.matchbox_script,
        params.matchbox_parameters,
        params.nanobody,
    )

    publish:
    barcode_file        = abprep.barcode_file
    bam_file            = abprep.bam_file
    bam_index           = abprep.bam_index
    flagstat            = abprep.flagstat
    stats               = abprep.stats
    read_lengths        = abprep.read_lengths
    matchbox_stats_best = abprep.matchbox_stats_best
    matchbox_files_best = abprep.matchbox_files_best
    matchbox_stats_all  = abprep.matchbox_stats_all
    matchbox_files_all  = abprep.matchbox_files_all
    riot_files_best     = abprep.riot_files_best
    riot_files_all      = abprep.riot_files_all

    onComplete:
    def status = workflow.success ? "SUCCESS ✅" : "FAILED ❌"

    println "\n"
    println "============================================================================"
    println "Pipeline execution summary"
    println "============================================================================"
    println "Completed at       : ${workflow.complete}"
    println "Duration           : ${workflow.duration}"
    println "Pipeline finished  : ${status}"
    println "exit status        : ${workflow.exitStatus}"
    println ""

    onError:
    println "Error: Pipeline execution stopped with the following message: ${workflow.errorMessage}".stripIndent()
}

// Set output paths
output {
    barcode_file {
        path "combined_reads"
    }
    bam_file {
        path "samtools/bam_files"
    }
    bam_index {
        path "samtools/bam_files"
    }
    flagstat {
        path "samtools/stats"
    }
    stats {
        path "samtools/stats"
    }
    read_lengths {
        path "samtools/read_lengths"
    }
    matchbox_stats_best {
        path "matchbox/best/counts"
    }
    matchbox_files_best {
        path "matchbox/best/fasta_files"
    }
    matchbox_stats_all {
        path "matchbox/all/counts"
    }
    matchbox_files_all {
        path "matchbox/all/fasta_files"
    }
    riot_files_best {
        path "riot/best"
    }
    riot_files_all {
        path "riot/all"
    }
}
