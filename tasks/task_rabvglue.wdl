version 1.0

task rabv_genotype {
    input {
        File assembly_fasta
        String docker = "us-docker.pkg.dev/general-theiagen/theiagen/rabvglue:1.1.113"
        Int cpu = 4
        Int memory = 8
        Int disk_size = 100
    }

    command <<<
        #set -euo pipefail to avoid silent failure
        set -euo pipefail

        rabv-analyze.sh ~{assembly_fasta} rabies_genotype.txt

        # Extract the query name, major clade, and minor clade from the rabies_genotype.txt file
        query_name=$(grep "|" rabies_genotype.txt | grep -v "query" | grep -v "===" | head -n 1 | awk -F'|' '{print $2}' | xargs)
        major_clade=$(grep "|" rabies_genotype.txt | grep -v "query" | grep -v "===" | head -n 1 | awk -F'|' '{print $3}' | xargs)
        minor_clade=$(grep "|" rabies_genotype.txt | grep -v "query" | grep -v "===" | head -n 1 | awk -F'|' '{print $4}' | xargs)

        # If no major or minor clade is found, set to "No major/minor clade found as marked by '-'"
        if [ "$major_clade" = "-" ]; then
            major_clade="No major clade found"
        fi
        if [ "$minor_clade" = "-" ]; then
            minor_clade="No minor clade found"
        fi

        echo "$query_name" > query_name.txt
        echo "$major_clade" > major_clade.txt
        echo "$minor_clade" > minor_clade.txt
    >>>

    output {
        String query_name = sub(read_string("query_name.txt"), "_.*$", "")
        String major_clade = read_string("major_clade.txt")
        String minor_clade = read_string("minor_clade.txt")
    }

    runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    maxRetries: 1
    preemptible: 0
  }
}