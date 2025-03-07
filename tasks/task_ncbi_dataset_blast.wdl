version 1.0

task ncbi_datasets_blast {
  input {
    String accession
    Int cpu = 1
    Int memory = 4
    String docker = "us-docker.pkg.dev/general-theiagen/staphb/ncbi-datasets:16.38.1" # not the latest version, but it's hard to keep up w/ the frequent releases
    Int disk_size = 50
  }
  meta {
    # added so that call caching is always turned off 
    volatile: true
  }
  
  # Clean up the accession number (extract everything before the first underscore)
  String ncbi_accession = sub(accession, "_.*$", "")
  
  command <<<
    date | tee DATE
    datasets --version | sed 's|datasets version: ||' | tee DATASETS_VERSION

    echo "Downloading the virus genome accession: ~{ncbi_accession}"

    # For refnaap / rabvglue we only want to do the virus download
    datasets download virus genome accession \
    ~{ncbi_accession} \
    --filename ~{ncbi_accession}.zip \
    --include genome 

    unzip ~{ncbi_accession}.zip
    cp -v ncbi_dataset/data/genomic.fna ./~{ncbi_accession}.fasta
    cp -v ncbi_dataset/data/data_report.jsonl ./~{ncbi_accession}.data_report.jsonl
  >>>
  
  output {
    File ncbi_datasets_reference_fasta = "~{ncbi_accession}.fasta"
    File ncbi_datasets_report = "~{ncbi_accession}.data_report.jsonl"
    String ncbi_datasets_version = read_string("DATASETS_VERSION")
    String ncbi_datasets_docker = docker
  }
  
  runtime {
    memory: "~{memory} GB"
    cpu: cpu
    docker: docker
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    maxRetries: 3
  }
}