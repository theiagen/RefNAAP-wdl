import sys
import re
import logging

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def parse_blast_results(blast_file):
    """Parse BLAST results file and return a list of records."""
    results = []
    with open(blast_file, 'r') as f:
        # Skip header line
        next(f)
        for line in f:
            if line.strip():
                results.append(line.strip().split('\t'))
    return results

def parse_header_file(header_file):
    """Parse header file and return a dictionary mapping subject_id to gene name."""
    subject_to_gene = {}
    with open(header_file, 'r') as f:
        for line in f:
            if line.startswith('>'):
                # Extract subject ID (the part before the space)
                parts = line.strip()[1:].split()
                subject_id = parts[0]
                
                # Determine gene name based on text in the line
                if "phosphoprotein" in line:
                    gene_name = "phosphoprotein"
                elif "matrix protein" in line:
                    gene_name = "matrix protein"
                elif "glycoprotein" in line:
                    gene_name = "glycoprotein"
                elif "polymerase" in line:
                    gene_name = "polymerase"
                elif "nucleoprotein" in line:
                    gene_name = "nucleoprotein"
                else:
                    gene_name = "unknown"
                
                subject_to_gene[subject_id] = gene_name
    return subject_to_gene

def gene_to_nomenclature(gene_name):
    """Convert gene name to common nomenclature for Rabies."""
    mapping = {
        "nucleoprotein": "N",
        "polymerase": "L",
        "phosphoprotein": "P",
        "glycoprotein": "G",
        "matrix protein": "M"
    }
    return mapping.get(gene_name, "unknown")

def main():
    if len(sys.argv) != 4:
        logger.error("Usage: python script.py <min_identity_threshold> <blast_results_file> <header_file>")
        sys.exit(1)
    
    min_identity_threshold = float(sys.argv[1])
    blast_file = sys.argv[2]
    header_file = sys.argv[3]
    logger.info(f"Using min_identity_threshold: {min_identity_threshold}")
    
    blast_results = parse_blast_results(blast_file)
    subject_to_gene = parse_header_file(header_file)
    
    # Check if any hit has percent identity above threshold
    any_above_threshold = False
    for result in blast_results:
        if float(result[2]) >= min_identity_threshold:
            any_above_threshold = True
            break
    
    # Write identification result to rabv_identification.txt - just for Yes or No answer
    with open('rabv_identification.txt', 'w') as f:
        if any_above_threshold:
            logger.info("Rabies virus detected.")
            f.write("Yes\n")
        else:
            logger.info("Rabies virus not detected.")
            f.write("No\n")
    
    # If we have hits above threshold, create gene_coverage.txt
    if any_above_threshold:
        logger.info("Identifying genes, identification above threshold detected...")
        # Find the top hit for each gene
        gene_coverage = {}
        for result in blast_results:
            subject_id = result[1]
            # Percent identity is the 3rd column
            percent_identity = float(result[2])
            # Query coverage is the 13th column
            query_coverage = float(result[12]) 
            
            if subject_id in subject_to_gene:
                gene_name = subject_to_gene[subject_id]
                
                # Only consider hits that meet the threshold
                if percent_identity >= min_identity_threshold:
                    # If we haven't seen this gene yet or this is a better hit, update
                    if gene_name not in gene_coverage or query_coverage > gene_coverage[gene_name]:
                        gene_coverage[gene_name] = query_coverage
        
        # Report gene coverage using common nomenclature
        with open('gene_coverage.txt', 'w') as f:
            for gene_name in ["phosphoprotein", "matrix protein", "glycoprotein", "polymerase", "nucleoprotein"]:
                nomenclature = gene_to_nomenclature(gene_name)
                coverage = gene_coverage.get(gene_name, 0)
                f.write(f"{nomenclature}: {coverage:.2f}%\n")

if __name__ == "__main__":
    main()