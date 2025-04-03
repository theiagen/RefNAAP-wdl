version 1.0

task ncbi_datasets_blast {
  input {
    String accession
    File refnaap_assembly
    Int cpu = 4
    Int memory = 8
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/ncbi-datasets-blast:16.38.1_20250403"
    Int disk_size = 50
    String blast_evalue = "1e-10"
    Float min_percent_identity = 75.0
    Float min_gene_coverage = 75.0
  }
  meta {
    volatile: true
  }
  
  command <<<
    date | tee DATE
    datasets --version | sed 's|datasets version: ||' | tee DATASETS_VERSION

    echo "Downloading the virus genome accession: ~{accession}"

    # For refnaap / rabvglue we only want to do the virus download
    datasets download virus genome accession \
    ~{accession} \
    --filename ~{accession}.zip \
    --include cds

    unzip ~{accession}.zip
    cp -v ncbi_dataset/data/cds.fna ./~{accession}_cds.fasta
    cp -v ncbi_dataset/data/data_report.jsonl ./~{accession}.data_report.jsonl

    # Make intermitent files for blast headers for down stream analysis
    grep ">" ~{accession}_cds.fasta > rabv_cds_headers.txt

    # Make blast database from the downloaded virus genome
    makeblastdb -in ~{accession}_cds.fasta -dbtype nucl -out virus_db

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
    
    python3 /scripts/identify-genes.py --blast_file blast_results.tsv \
            --header_file rabv_cds_headers.txt \
            --min_identity ~{min_percent_identity} \
            --min_gene_coverage ~{min_gene_coverage}

    # If gene_coverage.txt doesn't exist (no hits above threshold), create it with zeros
    if [ ! -f gene_coverage.txt ]; then
      echo "N: 0.00" > gene_coverage.txt
      echo "P: 0.00" >> gene_coverage.txt
      echo "M: 0.00" >> gene_coverage.txt
      echo "G: 0.00" >> gene_coverage.txt
      echo "L: 0.00" >> gene_coverage.txt
    fi
    
    # Extract each gene's coverage value as float
    grep "^N:" gene_coverage.txt | cut -d' ' -f2 | sed 's/%//' > n_gene_coverage.txt
    grep "^P:" gene_coverage.txt | cut -d' ' -f2 | sed 's/%//' > p_gene_coverage.txt
    grep "^M:" gene_coverage.txt | cut -d' ' -f2 | sed 's/%//' > m_gene_coverage.txt
    grep "^G:" gene_coverage.txt | cut -d' ' -f2 | sed 's/%//' > g_gene_coverage.txt
    grep "^L:" gene_coverage.txt | cut -d' ' -f2 | sed 's/%//' > l_gene_coverage.txt
  >>>
  
  output {
    File ncbi_datasets_reference_fasta = "~{accession}_cds.fasta"
    File ncbi_datasets_report = "~{accession}.data_report.jsonl"
    String ncbi_datasets_version = read_string("DATASETS_VERSION")
    File blast_results = "blast_results.tsv"
    String rabv_identification = read_string("rabv_identification.txt")
    String ncbi_datasets_docker = docker
    Float n_gene_coverage = read_string("n_gene_coverage.txt")
    Float p_gene_coverage = read_string("p_gene_coverage.txt")
    Float m_gene_coverage = read_string("m_gene_coverage.txt")
    Float g_gene_coverage = read_string("g_gene_coverage.txt")
    Float l_gene_coverage = read_string("l_gene_coverage.txt")
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