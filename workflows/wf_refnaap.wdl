version 1.0

import "../tasks/task_refnaap.wdl" as refnaap_task
import "../tasks/task_rabvglue.wdl" as rabvglue_task
import "../tasks/task_ncbi_dataset_blast.wdl" as ncbi_datasets_blast

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
  call rabvglue_task.rabv_genotype {
    input: 
      assembly_fasta=refnaap.refnaap_assembly_fasta
  }
  call ncbi_datasets_blast.ncbi_datasets_blast {
    input: 
      refnaap_assembly=refnaap.refnaap_assembly_fasta,
      accession=rabv_genotype.query_name
  }
  output {
    String refnaap_docker = refnaap.refnaap_docker
    String refnaap_analysis_date = refnaap.refnaap_analysis_date
    File refnaap_assembly_fasta = refnaap.refnaap_assembly_fasta
    File refnaap_multiqc_report = refnaap.refnaap_multiqc_report
    String rabvglue_major_clade = rabv_genotype.major_clade
    String rabvglue_minor_clade = rabv_genotype.minor_clade
    String rabvglue_query_name = rabv_genotype.query_name
    String ncbi_datasets_docker = ncbi_datasets_blast.ncbi_datasets_docker
    String ncbi_datasets_version = ncbi_datasets_blast.ncbi_datasets_version
    File ncbi_datasets_reference_fasta = ncbi_datasets_blast.ncbi_datasets_reference_fasta
    File ncbi_datasets_report = ncbi_datasets_blast.ncbi_datasets_report
    File blast_results = ncbi_datasets_blast.blast_results
    File blast_summary = ncbi_datasets_blast.blast_summary
  }
}