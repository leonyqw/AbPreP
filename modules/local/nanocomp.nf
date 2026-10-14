/*
Utilize nanocomp to get read length statistics.
*/

//Enable typed processes
nextflow.enable.types = true

process NANOCOMP {

	label "process_medium"

	// Enable conda and install nanocomp if conda profile is set
	conda (params.enable_conda ? 'bioconda::nanocomp=1.25.6' : null)

	// Use Singularity container or pull from Docker container for nanocomp v1.25.6 (linux/amd64) if singularity profile is enabled
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanocomp:1.25.6--pyhdfd78af_0':
        'quay.io/biocontainers/nanocomp:1.25.6--pyhdfd78af_0' }"

    input:
	// (barcode, read_file): Tuple<String, Path> 
	// Record for sample name, and path for DNA sequence fastq files
    files: List<Path>
	
	// Output tuple with sample name and sam file
	output:
	// minimap_out = tuple(barcode, file("${barcode}_aligned.sam"))
	file("NanoStats.txt")
	
	/*
	Run minimap, mapping reads to a reference and outputs a sam file
	-a			Generates CIGAR and outputs alignments in sam format
	-x map-ont	Sets preset for ONT alignment
	-t 8		Use 8 threads
	-o			Output alignments to sam file
	*/
    script:
	//determine input file type
    def filetypes = []
    files.each { file ->
        def tokenized_filename = file.getName().tokenize('.')
        if (tokenized_filename.size() < 2) {
            error "Every input file to nanocomp has to have a file ending."
        }

        def extension_found = false

        // Skip the first part (actual filename) and check extensions
        tokenized_filename.drop(1).each { namepart ->
            if (namepart && !extension_found) {
                if (["fq", "fastq"].contains(namepart)) {
                    filetypes.add("fastq")
                    extension_found = true
                } else if (["fasta", "fna", "ffn", "faa", "frn", "fa"].contains(namepart)) {
                    filetypes.add("fasta")
                    extension_found = true
                } else if (namepart == "bam") {
                    filetypes.add("bam")
                    extension_found = true
                } else if (namepart == "txt") {
                    filetypes.add("summary")
                    extension_found = true
                }
            }
        }
    
        if (!extension_found) {
            error "There was no suitable filetype found for ${file.getName()}. NanoComp only accepts fasta (fasta, fna, ffn, faa, frn, fa), fastq (fastq, fq), bam and Nanopore sequencing summary (txt)."
        }
    }

    filetypes.unique()
    if (filetypes.size() < 1){
        throw new java.lang.IllegalArgumentException("There was no suitable filetype found in NanoComp input. Please use fasta, fastq, bam or Nanopore sequencing summary.")
    }
    if (filetypes.size() > 1){
        throw new java.lang.IllegalArgumentException("You gave different filetypes to NanoComp. Please use only *one* of fasta, fastq, bam or Nanopore sequencing summary.")
    }
    filetype = filetypes[0]

    // println((files))
    // println "files class: ${files.getClass()}"
    // println "element classes: ${files.collect { it.getClass() }.unique()}"

    // test = files.join(" ")
    // println((test.join("")))
    // println "files class: ${test.getClass()}"
    // println "element classes: ${test.collect { it.getClass() }.unique()}"

    """
    NanoComp \\
        --${filetype} ${files.join(" ")} \\
        # --threads ${task.cpus} \\
        # ${args}
    """

	stub:
	"""
	touch NanoStats.txt
	"""
}