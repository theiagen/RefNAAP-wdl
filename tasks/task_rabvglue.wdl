version 1.0

task rabv_genotype {
    input {
        File assembly_fasta
        String docker = "us-docker.pkg.dev/general-theiagen/theiagen/rabvglue:1.1.113_20250319"
        Int cpu = 4
        Int memory = 8
        Int disk_size = 50
    }

    command <<<
        set -euo pipefail

        rabv-genotype-reference.sh ~{assembly_fasta} rabies_genotype

        # Extract values from rabies_genotype file
        closest_reference=$(awk -F'\t' 'NR==1 {print $1}' rabies_genotype)
        major_clade=$(awk -F'\t' 'NR==1 {print $2}' rabies_genotype)
        minor_clade=$(awk -F'\t' 'NR==1 {print $3}' rabies_genotype)

        echo $closest_reference > closest_reference.txt
        echo $major_clade > major_clade.txt
        echo $minor_clade > minor_clade.txt
        
    >>>

    output {
        String closest_reference = read_string("closest_reference.txt")
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