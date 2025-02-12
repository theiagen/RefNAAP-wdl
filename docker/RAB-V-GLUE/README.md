# RABV-GLUE Docker Image

This Docker image combines the GLUE tools and MySQL database required for rabies virus (RABV) genotyping analysis. It's designed to provide a self-contained environment for analyzing RABV sequences so that it can work on Terra.

## Components

### MySQL Database
The image includes a MySQL 5.7 instance that:
- Starts automatically when the container runs
- Contains the pre-loaded RABV reference data from the source database: http://rabv-glue.cvr.gla.ac.uk/rabv_glue_dbs/ncbi_rabv_glue.sql.gz
- Is configured for local access only -- satisfies requirements for our use case

### GLUE Tools
The GLUE software package is installed with:
- Core analysis tools
- Required dependencies (MAFFT, RAxML, BLAST+)
- Configuration files 
- Loaded RABV project data

### rabv-analyze.sh Script
A convenience script that:
- Takes a FASTA file as input
- Ensures MySQL is running
- Executes the RABV genotyping analysis module
- Outputs clade assignment results
- Cleans the output for easy parsing

## Usage

### Basic Usage
```bash
# Run the genotyping analysis
rabv-analyze.sh input.fasta output.txt

# Output format
+====================+=======================+=======================+
|     queryName      | major_cladeFinalClade | minor_cladeFinalClade |
+====================+=======================+=======================+
| sequence1          | AL_Cosmopolitan       | AL_Cosmopolitan_AF1b  |
+====================+=======================+=======================+
```