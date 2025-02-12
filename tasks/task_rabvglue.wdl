version 1.0

task rabv_genotype {
    input {
        File assembly_fasta
        String docker = "rabvglue:dev"
        Int cpu = 4
        Int memory = 8
        Int disk_size = 100
    }

    command <<<
        #set -euo pipefail to avoid silent failure
        set -euo pipefail

        rabv-analyze.sh genotype ~{assembly_fasta} rabies_genotype.txt
    >>>

    output {
        File genotype_results = "rabies_genotype.txt"
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