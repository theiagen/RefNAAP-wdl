version 1.0

task refnaap {
  input {
    File read1
    String samplename
    String model = "r10_min_high_g303"
    Int size = 50
    Int trim_right = 25
    Int trim_left = 25
    Int min_coverage = 5

    String docker = "us-docker.pkg.dev/general-theiagen/internal/refnaap:b3ad097"
    Int cpu = 8
    Int memory = 16
    Int disk_size = 100
  }
  command <<<
    date | tee DATE

    # Move reads to expected directory
    mkdir -p reads
    cp ~{read1} reads/

    # create outdir
    mkdir -p refnaap

    # get the read name from file without extension
    PATTERN="\.f(q|astq)(\.gz)?$" # match .fastq or .fastq.gz
    wgsid=$(basename ~{read1} | sed -E "s/$PATTERN//")
    >&2 echo "DEBUG: wgsid: $wgsid"

    # Run the pipeline
    if RefNAAP_CLI.py -i $PWD/reads -o $PWD/refnaap --threads ~{cpu} --MinCov ~{min_coverage} --model ~{model} --Size ~{size} --Right ~{trim_right} --Left ~{trim_left}
    then
        # output files - move to root directory
        if [[ -f "refnaap/${wgsid}_final_scaffold.fasta" ]]; then
            mv "refnaap/${wgsid}_final_scaffold.fasta" ~{samplename}.fasta
        fi
        if [[ -f "refnaap/multiqc_report.html" ]]; then
            mv "refnaap/multiqc_report.html" ~{samplename}.multiqc_report.html
        fi
    else
        # Run failed
        exit 1
    fi
  >>>
  output {
    String refnaap_docker = docker
    String refnaap_analysis_date = read_string("DATE")
    File refnaap_assembly_fasta = "~{samplename}.fasta"
    File refnaap_multiqc_report = "~{samplename}.multiqc_report.html"
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    maxRetries: 0
    preemptible: 0
  }
}