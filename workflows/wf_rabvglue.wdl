version 1.0

import "../tasks/task_rabvglue.wdl" as rabvglue_task

workflow rabvglue_wf {
  meta {
    description: "A WDL workflow that just runs RaBVGlue for genotyping"
  }
  input {
    File assembly_fasta
  }

  call rabvglue_task.rabv_genotype {
    input: 
      assembly_fasta = assembly_fasta
  }

  output {
    String rabvglue_major_clade = rabv_genotype.major_clade
    String rabvglue_minor_clade = rabv_genotype.minor_clade
    String rabvglue_closest_reference = rabv_genotype.closest_reference
  }
}