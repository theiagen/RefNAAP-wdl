import argparse
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
                # Extract subject ID 
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
    # We don't know the nomenclature for unknown genes
    return mapping.get(gene_name, "unknown")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Detect Rabies virus from BLAST results and report gene coverage.')
    parser.add_argument('--blast_file', type=str, required=True,
                        help='Path to BLAST results file')
    parser.add_argument('--header_file', type=str, required=True,
                        help='Path to header file')
    parser.add_argument('--min_identity', type=float, required=True, 
                        help='Minimum percent identity threshold for detection')
    parser.add_argument('--min_gene_coverage', type=float, required=True,
                        help='Minimum gene coverage threshold for detection')
    
    args = parser.parse_args()
    
    min_identity_threshold = args.min_identity
    min_gene_coverage_threshold = args.min_gene_coverage
    blast_file = args.blast_file
    header_file = args.header_file
    
    logger.info(f"Using min_identity_threshold: {min_identity_threshold}")
    logger.info(f"Using min_gene_coverage_threshold: {min_gene_coverage_threshold}")
    
    blast_results = parse_blast_results(blast_file)
    subject_to_gene = parse_header_file(header_file)
    
    # Find the top hit for each gene
    gene_coverage = {}
    max_identity = {}
    
    for result in blast_results:
        subject_id = result[1]
        # Percent identity is the 3rd column
        percent_identity = float(result[2])
        # Query coverage is the 13th column
        query_coverage = float(result[12])
        
        if subject_id in subject_to_gene:
            gene_name = subject_to_gene[subject_id]
            
            # If we haven't seen this gene yet or this is a better hit, update
            if gene_name not in gene_coverage or query_coverage > gene_coverage[gene_name]:
                gene_coverage[gene_name] = query_coverage
                max_identity[gene_name] = percent_identity
    
    # Check if any gene meets both thresholds - if so, we have a positive identification
    any_gene_meets_thresholds = False # This is the flag to set if any gene meets thresholds
    any_gene_present = False # This just captures if any gene is present at all
    
    for gene_name in gene_coverage:
        coverage = gene_coverage.get(gene_name, 0)
        identity = max_identity.get(gene_name, 0)
        
        if coverage > 0 or identity > 0:
            # If we have any coverage or identity over 0, we know this gene is present
            any_gene_present = True
            
        if coverage >= min_gene_coverage_threshold and identity >= min_identity_threshold:
            # If both coverage and identity meet thresholds, we have a positive identification
            any_gene_meets_thresholds = True
    
    # Write identification result to rabv_identification.txt
    with open('rabv_identification.txt', 'w') as f:
        # Main logic to determine if Rabies virus is detected
        if any_gene_meets_thresholds:
            logger.info("Rabies virus detected.")
            f.write("Yes")
        # If any gene is present, but none meet thresholds, we can't be sure
        elif any_gene_present:
            logger.info("Possible Rabies virus detected, but below threshold.")
            f.write("Unknown")
        # Otherwise, no Rabies virus detected
        else:
            logger.info("Rabies virus not detected.")
            f.write("No")
    
    logger.info("Identifying genes and writing gene coverage...")
    
    # Report gene coverage using common nomenclature (N, L, P, G, M)
    with open('gene_coverage.txt', 'w') as f:
        for gene_name in ["phosphoprotein", "matrix protein", "glycoprotein", "polymerase", "nucleoprotein"]:
            nomenclature = gene_to_nomenclature(gene_name)
            coverage = gene_coverage.get(gene_name, 0)
            f.write(f"{nomenclature}: {coverage:.2f}%\n")
            
if __name__ == "__main__":
    main()