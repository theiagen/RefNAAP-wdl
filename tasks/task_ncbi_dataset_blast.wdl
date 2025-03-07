version 1.0

task ncbi_datasets_blast {
  input {
    String accession
    File refnaap_assembly
    Int cpu = 4
    Int memory = 8
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/ncbi-datasets-blast:16.38.1"
    Int disk_size = 50
    String blast_evalue = "1e-10"
    Float min_identity_threshold = 75.0
  }
  meta {
    # added so that call caching is always turned off 
    volatile: true
  }
  
  # Clean up accesion from RaBVGlue output
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

    # Make blast database from the downloaded virus genome
    makeblastdb -in ~{ncbi_accession}.fasta -dbtype nucl -out virus_db

    # Run blast comparing refnaap assembly against the virus genome
    blastn -query ~{refnaap_assembly} \
           -db virus_db \
           -out blast_results.txt \
           -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs" \
           -evalue ~{blast_evalue} \
           -num_threads ~{cpu}
    
    # We can use headers to make the output more readable
    echo -e "query_id\tsubject_id\tpercent_identity\talignment_length\tmismatches\tgap_opens\tquery_start\tquery_end\tsubject_start\tsubject_end\tevalue\tbit_score\tquery_coverage" > blast_results.tsv
    cat blast_results.txt >> blast_results.tsv
    
    # For now let's just print out some summary statistics, but later we can scrape this
    echo "=== BLAST Summary Statistics ===" > blast_summary.txt
    echo "Top hit percent identity: $(head -n 1 blast_results.txt | cut -f 3)" >> blast_summary.txt
    echo "Top hit alignment length: $(head -n 1 blast_results.txt | cut -f 4)" >> blast_summary.txt
    echo "Top hit e-value: $(head -n 1 blast_results.txt | cut -f 11)" >> blast_summary.txt
    echo "Total hits: $(wc -l < blast_results.txt)" >> blast_summary.txt

    # Do comparison to threshold for RABV identification
    TOP_IDENTITY=$(head -n 1 blast_results.txt | cut -f 3)
    # Multiply by 100 and convert to integer and preserve 2 decimals
    TOP_IDENTITY_INT=$(printf "%.0f" $(echo "$TOP_IDENTITY * 100" | tr -d '.'))
    THRESHOLD_INT=$(printf "%.0f" $(echo "~{min_identity_threshold} * 100" | tr -d '.'))
    # If the top hit identity is greater than the threshold, we can say it's RABV
    if [ "$TOP_IDENTITY_INT" -ge "$THRESHOLD_INT" ]; then
        echo "Yes" > RABV_IDENTIFICATION
    else
        echo "No" > RABV_IDENTIFICATION
    fi
  >>>
  
  output {
    File ncbi_datasets_reference_fasta = "~{ncbi_accession}.fasta"
    File ncbi_datasets_report = "~{ncbi_accession}.data_report.jsonl"
    String ncbi_datasets_version = read_string("DATASETS_VERSION")
    File blast_results = "blast_results.tsv"
    File blast_summary = "blast_summary.txt"
    String rabv_identification = read_string("RABV_IDENTIFICATION")
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