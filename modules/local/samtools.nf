/*
Utilize samtools to write SAM file to BAM file.
*/

//Enable typed processes
nextflow.enable.types = true

process SAMTOOLS {
	tag "${barcode}"
	label "process_high"

	// Enable conda and install samtools if conda profile is set
	conda (params.enable_conda ? 'bioconda::samtools=1.22.1' : null)

	// Use Singularity container or pull from Docker container for samtools v1.22.1 (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/samtools:1.22.1--9a10f06c24cdf05f' :
    'community.wave.seqera.io/library/samtools:1.22.1--eccb42ff8fb55509' }"

    input:
	// Record for sample name, and path for aligned reads after minimap2
	// (barcode, aligned_read_file): Tuple<String, Path> 
	record(
		barcode: String, 
		file: Path
	)
	
	// Output aligned reads, bam index file, and aligned QC statistics
	output:
	// record(
	// 	barcode: barcode, 
	// 	aligned_sorted_read: file("${barcode}_aligned_sorted.bam"), 
	// 	index: file("${barcode}_aligned_sorted.bam.bai"), 
	// 	aligned_stats: file("${barcode}_flagstat.txt"), 
	// 	read_lengths: file("${barcode}_read_lengths.tsv")
	// )
	aligned_sorted_read: Path = file("${barcode}_aligned_sorted.bam")
	index: Path = file("${barcode}_aligned_sorted.bam.bai")
	flagstat: Path = file("${barcode}_flagstat.txt")
	stats: Path = file("${barcode}_stats.txt")
	read_lengths: Path = file("${barcode}_read_lengths.tsv")

    script:
    """
	# View and convert file from SAM to BAM format. Sort alignments and outputs the file in BAM format
	samtools view -b "${file}" | samtools sort -o "${barcode}_aligned_sorted.bam"
	
	# Index BAM file for fast random access
	samtools index "${barcode}_aligned_sorted.bam"
	
	# Counts the number of alignments for each FLAG type
	samtools flagstat -O txt "${barcode}_aligned_sorted.bam" > "${barcode}_flagstat.txt"

	# Counts the number of alignments for each FLAG type
	samtools stats "${barcode}_aligned_sorted.bam" > "${barcode}_stats.txt"

	# Output read lengths for primary alignments as a text file
	# samtools view "${barcode}_aligned_sorted.bam" -F 256 -F 2048 | awk -v bc="${barcode}" 'BEGIN{OFS="\t"; print "barcode","read_length"} {print bc, length(\$10)}' > ${barcode}_read_lengths.tsv

	# Extract read lengths
	samtools view "${barcode}_aligned_sorted.bam" -F 256 -F 2048 | awk '{print length(\$10)}' > ${barcode}_read_lengths.tsv
	"""

	stub:
	"""
	touch ${barcode}_aligned_sorted.bam
	touch ${barcode}_aligned_sorted.bam.bai
	touch ${barcode}_flagstat.txt
	touch ${barcode}_stats.txt
	touch ${barcode}_read_lengths.tsv
	"""
}