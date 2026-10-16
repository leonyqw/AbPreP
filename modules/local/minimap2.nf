/*
Utilize minimap2 to align Oxford Nanopore DNA read sequences contained in fastq files against a reference genome database. The aligned sequence is output as a SAM file.
*/

//Enable typed processes
nextflow.enable.types = true

process MINIMAP2 {
	
	tag "${barcode}"
	label "process_high"

	// Enable conda and install minimap2 if conda profile is set
	conda (params.enable_conda ? 'bioconda::minimap2=2.30' : null)
	
	// Use Singularity container or pull from Docker container for minimap2 v2.30 (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/minimap2:2.30--3bf3d6cb39a98dae' :
    'community.wave.seqera.io/library/minimap2:2.30--dde6b0c5fbc82ebd' }"

    input:
	// (barcode, read_file): Tuple<String, Path> 
	// Record for sample name, and path for DNA sequence fastq files
	record(
        barcode: String,
        file: Path
	)
	reference: Path // Path for reference genome
	
	// Output tuple with sample name and sam file
	output:
	// minimap_out = tuple(barcode, file("${barcode}_aligned.sam"))
	minimap_out = record(
					barcode: barcode, 
					file: file("${barcode}_aligned.sam")
				)

	/*
	Run minimap, mapping reads to a reference and outputs a sam file
	-a			Generates CIGAR and outputs alignments in sam format
	-x map-ont	Sets preset for ONT alignment
	-t 8		Use 8 threads
	-o			Output alignments to sam file
	*/
    script:
    """
	minimap2 \\
	-t 8 \\
	-ax map-ont \\
	${reference} \\
	${file} \\
	-o "${barcode}_aligned.sam"
    """

	stub:
	"""
	touch ${barcode}_aligned.sam
	"""
}

// record Sample {
//         barcode: String
//         file: Path
// }