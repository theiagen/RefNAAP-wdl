#!/usr/bin/env python2
import sys
import xml.etree.ElementTree as ET
import re

def clean_xml(input_file, output_file):
    """Clean the GLUE output to extract only the valid XML."""
    with open(input_file, 'r') as f:
        content = f.read()
    
    xml_match = re.search(r'(<\?xml.*?</genotypingDocumentResult>)', content, re.DOTALL)
    if xml_match:
        with open(output_file, 'w') as f:
            f.write(xml_match.group(1))
        return True
    return False

def parse_glue_output(xml_file):
    """Parse the XML output from GLUE tools."""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        # Changed to findall since there could be multiple queryGenotypingResults
        query_results_list = root.findall('queryGenotypingResults')
        
        best_ref = None
        major_clade = None
        minor_clade = None
        
        if not query_results_list:
            print("Error: Could not find queryGenotypingResults in XML")
            return best_ref, major_clade, minor_clade
        
        # Use the first queryGenotypingResults for now
        query_results = query_results_list[0]
        
        for clade_category in query_results.findall('queryCladeCategoryResult'):
            category_name_elem = clade_category.find('categoryName')
            
            if category_name_elem is None:
                continue
                
            category_name = category_name_elem.text
            
            # For both major and minor clade categories, look for reference IDs
            # Try to get closestTargetSequenceID first
            closest_target_elem = clade_category.find('closestTargetSequenceID')
            closest_member_elem = clade_category.find('closestMemberSequenceID')
            
            # If we found a valid target sequence ID, use it
            if closest_target_elem is not None and closest_target_elem.text not in [None, "null"]:
                best_ref = closest_target_elem.text
            # Otherwise, try to use the member sequence ID as fallback
            elif best_ref is None and closest_member_elem is not None and closest_member_elem.text not in [None, "null"]:
                best_ref = closest_member_elem.text
            
            # Now get the clade information
            if category_name == 'major_clade':
                major_clade_elem = clade_category.find('finalCladeRenderedName')
                if major_clade_elem is not None and major_clade_elem.text is not None:
                    major_clade = major_clade_elem.text
            
            elif category_name == 'minor_clade':
                minor_clade_elem = clade_category.find('finalCladeRenderedName')
                if minor_clade_elem is not None and minor_clade_elem.text not in [None, "null"]:
                    minor_clade = minor_clade_elem.text
        
        return best_ref, major_clade, minor_clade
        
    except Exception as e:
        print("Error parsing XML: {}".format(e))
        return None, None, None

def main():
    if len(sys.argv) != 3:
        print("Usage: {} input_xml output_file".format(sys.argv[0]))
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Clean the XML just to be sure
    cleaned_xml = input_file + ".clean.xml"
    if not clean_xml(input_file, cleaned_xml):
        print("Error: Could not extract valid XML from input file")
        sys.exit(1)
    
    best_ref, major_clade, minor_clade = parse_glue_output(cleaned_xml)
    
    # Explicitly set defualts
    if best_ref is None:
        best_ref = "No Reference Found"
    if major_clade is None:
        major_clade = "No Major Clade Found"
    if minor_clade is None:
        minor_clade = "No Minor Clade Found"
    
    with open(output_file, 'w') as f:
        f.write("{}\t{}\t{}\n".format(best_ref, major_clade, minor_clade))
    
    print("Results extracted successfully:")
    print("Best reference: {}".format(best_ref))
    print("Major clade: {}".format(major_clade))
    print("Minor clade: {}".format(minor_clade))

if __name__ == "__main__":
    main()