version 1.0

import "../tasks/task_refnaap.wdl" as refnaap_task

workflow refnaap_wf {
  meta {
    description: "A WDL wrapper around RefNAAP CLI"
  }
  input {
    File read1
    String samplename
  }
  call refnaap_task.refnaap {
    input: 
      read1=read1,
      samplename=samplename
  }
  output {
    String refnaap_docker = refnaap.refnaap_docker
    String refnaap_analysis_date = refnaap.refnaap_analysis_date
    File refnaap_assembly_fasta = refnaap.refnaap_assembly_fasta
    File refnaap_multiqc_report = refnaap.refnaap_multiqc_report
  }
}