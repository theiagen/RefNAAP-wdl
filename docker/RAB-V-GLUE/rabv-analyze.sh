#!/bin/bash

function show_usage() {
    echo "Usage: $0 [fasta_file] [output_file]"
    echo "Example: $0 sequences.fasta results.txt"
    exit 1
}

# Check if the correct number of arguments is provided
# We want input and output files
if [ $# -lt 2 ]; then
    show_usage
fi

FASTA_FILE=$(readlink -f "$1")
OUTPUT_FILE=$2

# Start the MySQL instance on local if not running
if ! mysqladmin ping -h"localhost" --silent; then
    service mysql start
    # Echo message and wait for MySQL to be ready
    while ! mysqladmin ping -h"localhost" --silent; do
        echo "Waiting for MySQL to be ready..."
        sleep 1
    done
fi

# Run genotype module from GLUE tools
gluetools.sh << EOF > "$OUTPUT_FILE"
project rabv
module rabvMaxLikelihoodGenotyper genotype file --fileName $FASTA_FILE
quit
EOF

# Remove unnecessary lines from the output file
sed -i '/^GLUE>/d; /^OK$/d; /^Mode path:/d; /^quit$/d; /^GLUE Version/d; /^Copyright/d; /^This program/d; /^are welcome/d; /^GNU Affero/d; /^<userStyle>/d' "$OUTPUT_FILE"

# Module is interactive and throws out weird thinks like this:
# Mode path: /project/rabv
# GLUE> quit
# OK -- and a message about the GLUE version