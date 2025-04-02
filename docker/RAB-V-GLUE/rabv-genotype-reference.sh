#!/bin/bash

function show_usage() {
    echo "Usage: $0 [fasta_file] [output_file]"
    echo "Example: $0 sequences.fasta results.txt"
    exit 1
}

if [ $# -lt 2 ]; then
    show_usage
fi

FASTA_FILE="$1"
OUTPUT_FILE="$2"

# Start MySQL if needed
service mysql start &>/dev/null
while ! mysqladmin ping -h"localhost" --silent; do sleep 1; done

# Run GLUE analysis and capture output
gluetools.sh << GLUE_EOF > "$OUTPUT_FILE.xml.tmp"
project rabv
module rabvMaxLikelihoodGenotyper
genotype file -f "$FASTA_FILE" -c
quit
GLUE_EOF

# Clean up the GLUE output xml
sed -n '/<?xml version="1.0" encoding="UTF-8" standalone="no"?>/,/<\/genotypingDocumentResult>/p' $OUTPUT_FILE.xml.tmp > $OUTPUT_FILE.xml
# Parse the GLUE output
parse_glue_xml.py "$OUTPUT_FILE.xml" "$OUTPUT_FILE.parsed"

# Read the parsed output, script outputs sequence_id, major_clade, minor_clade
read SEQUENCE_ID MAJOR_CLADE MINOR_CLADE < "$OUTPUT_FILE.parsed"

# Query the database for the accession version
ACCESSION=$(mysql -u gluetools -pglue12345 GLUE_TOOLS -Ne "SELECT gb_accession_version FROM rabv_sequence WHERE sequence_id = '$SEQUENCE_ID' LIMIT 1;")

# Output the final results
echo -e "${ACCESSION}\t${MAJOR_CLADE}\t${MINOR_CLADE}" > "$OUTPUT_FILE"

echo "Analysis complete. Results saved to $OUTPUT_FILE"
echo "Sequence ID: $SEQUENCE_ID"
echo "Accession: $ACCESSION"
echo "Major Clade: $MAJOR_CLADE"
echo "Minor Clade: $MINOR_CLADE"

# Clean up temporary files
rm -f "$OUTPUT_FILE.xml" "$OUTPUT_FILE.xml.tmp" "$OUTPUT_FILE.parsed" "$OUTPUT_FILE.xml.clean.xml"