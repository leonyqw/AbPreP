/*
Utilize samtools to write SAM file to BAM file.
*/

//Enable typed processes
nextflow.enable.types = true

process SAMTOOLS {
	tag "${barcode}, file:${file_num}"
	label "process_medium"

	// Enable conda and install samtools if conda profile is set
	conda (params.enable_conda ? 'bioconda::samtools=1.22.1' : null)

	// Use Singularity container or pull from Docker container for samtools v1.22.1 (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/samtools:1.22.1--9a10f06c24cdf05f' :
    'community.wave.seqera.io/library/samtools:1.22.1--eccb42ff8fb55509' }"

    input:
	// Record for sample name, and path for aligned reads after minimap2
	record(
		barcode: String, 
		file_num: Integer,
		file: Path
	)
	
	// Output aligned reads, bam index file
	output:
	record(
		barcode: barcode,
		file_num: file_num,
		aligned_sorted_read: file("${barcode}-${file_num}_aligned_sorted.bam"),
		index: file("${barcode}-${file_num}_aligned_sorted.bam.bai")
	)

    script:
    """
	# View and convert file from SAM to BAM format. Sort alignments and outputs the file in BAM format
	samtools view -b "${file}" | samtools sort -o "${barcode}-${file_num}_aligned_sorted.bam"
	
	# Index BAM file for fast random access
	samtools index "${barcode}-${file_num}_aligned_sorted.bam"
	"""

	stub:
	"""
	touch ${barcode}-${file_num}_aligned_sorted.bam
	touch ${barcode}-${file_num}_aligned_sorted.bam.bai
	"""
}

/*
Utilize samtools to cat split samnple files together, and get stats.
*/
process SAMTOOLS_STATS {
	tag "${barcode}"
	label "process_medium"

	// Enable conda and install samtools if conda profile is set
	conda (params.enable_conda ? 'bioconda::samtools=1.22.1' : null)

	// Use Singularity container or pull from Docker container for samtools v1.22.1 (linux/amd64) if singularity profile is enabled
	container "${ (workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container) ?
    'oras://community.wave.seqera.io/library/samtools:1.22.1--9a10f06c24cdf05f' :
    'community.wave.seqera.io/library/samtools:1.22.1--eccb42ff8fb55509' }"

    input:
	// Record for sample name, and list of paths for aligned reads for each barcode sample
	record(
		barcode: String, 
		files: List<Path>
	)
	
	// Output aligned QC statistics and read lengths
	output:
	record(
		stats: file("${barcode}_stats.txt"),
		read_lengths: file("${barcode}_read_lengths.tsv")
	)

    script:
    """
	# Cat all bam files from same barcode together
	samtools cat ${files.join(' ')} -o "${barcode}_aligned_sorted.bam"

	# Counts the number of alignments for each FLAG type
	samtools stats "${barcode}_aligned_sorted.bam" > "${barcode}_stats.txt"

	# Extract read lengths
	samtools view "${barcode}_aligned_sorted.bam" -F 256 -F 2048 | awk '{print length(\$10)}' > "${barcode}_read_lengths.tsv"
	"""

	stub:
	"""
	touch ${barcode}_stats.txt
	touch ${barcode}_read_lengths.tsv
	"""
}