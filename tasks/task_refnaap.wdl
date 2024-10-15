version 1.0

task refnaap {
  input {
    File read1
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/internal/refnaap:b3ad097"
    Int cpu = 4
    Int memory = 8
  }
  command <<<
    date | tee DATE

    # Move reads to expected directory
    mkdir -p reads
    cp ~{read1} reads/

    # get the read name from file without extension
    wgsid=$(basename ~{read1} .fastq.gz)

    # Run the pipeline
    if RefNAAP_CLI.py -i $PWD/fastq -o $PWD/refnaap
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
    File assembly_fasta = "~{samplename}.fasta"
    File multiqc_report = "~{samplename}.multiqc_report.html"
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    maxRetries: 0
    preemptible: 0
  }
}