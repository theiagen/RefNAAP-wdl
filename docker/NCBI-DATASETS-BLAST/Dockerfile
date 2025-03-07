FROM us-docker.pkg.dev/general-theiagen/staphb/ncbi-datasets:16.38.1

# Install NCBI BLAST+
RUN apt-get update && apt-get install -y \
    ncbi-blast+ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN datasets --version && \
    blastn -version

# Set working directory
WORKDIR /data

# Default command
CMD ["/bin/bash"]