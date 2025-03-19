FROM ubuntu:16.04

ARG glueVersion=1.1.113
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
# Grabbed from the GLUE tools installation image
RUN apt-get install --no-install-recommends -y debconf-utils \
    python-software-properties \
    software-properties-common

# Add repository for OpenJDK 11
RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install --no-install-recommends -y openjdk-11-jre

# Install required packages
RUN apt-get install --no-install-recommends -y \
    git \
    make \
    gcc \
    libc6-dev \
    unzip \
    wget \
    curl

# Install MySQL 5.7 -- required for GLUE
RUN apt-get install --no-install-recommends -y mysql-server-5.7

# Create MySQL user and database -- mocking what glue-tools does
RUN service mysql start && \
    mysql -e "CREATE USER 'gluetools'@'localhost' IDENTIFIED BY 'glue12345';" && \
    mysql -e "CREATE DATABASE GLUE_TOOLS;" && \
    mysql -e "GRANT ALL PRIVILEGES ON GLUE_TOOLS.* TO 'gluetools'@'localhost';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Download and load the GLUE database
RUN service mysql start && \
    wget --no-check-certificate -O /tmp/ncbi_rabv_glue.sql.gz http://rabv-glue.cvr.gla.ac.uk/rabv_glue_dbs/ncbi_rabv_glue.sql.gz && \
    gunzip -c /tmp/ncbi_rabv_glue.sql.gz | mysql --user=gluetools --password=glue12345 GLUE_TOOLS && \
    rm /tmp/ncbi_rabv_glue.sql.gz
    

# Set up GLUE tools base structure
WORKDIR /opt
RUN wget -O glueInstallDir.zip http://glue-tools.cvr.gla.ac.uk/downloads/glueInstallDir-1.1.113.zip && \
    unzip glueInstallDir.zip && \
    rm glueInstallDir.zip

# Download and install GLUE jar
RUN mkdir -p /opt/gluetools/lib && \
    mkdir -p /opt/gluetools/projects && \
    wget -O /opt/gluetools/lib/gluetools-core.jar http://glue-tools.cvr.gla.ac.uk/downloads/gluetools-core-1.1.113.jar


# Setup build directory for RAxML, MAFFT, and BLAST+
RUN mkdir -p /builds

# RAxML
RUN cd /builds && git clone https://github.com/stamatak/standard-RAxML.git && \
    cd standard-RAxML/ && git checkout 3abe69b && \
    make -f Makefile.SSE3.PTHREADS.gcc && \
    mkdir -p /opt/gluetools/raxml/bin && \
    mkdir -p /opt/gluetools/tmp/raxmlfiles && \
    cp /builds/standard-RAxML/raxmlHPC-PTHREADS-SSE3 /opt/gluetools/raxml/bin

# MAFFT
RUN cd /builds && \
    wget https://mafft.cbrc.jp/alignment/software/mafft-7.407-with-extensions-src.tgz && \
    tar xvfz mafft-7.407-with-extensions-src.tgz && \
    cd mafft-7.407-with-extensions/core && \
    make clean && make && make install && \
    mkdir -p /opt/gluetools/tmp/mafftfiles

# BLAST+
RUN cd /builds && \
    wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.31/ncbi-blast-2.2.31+-x64-linux.tar.gz && \
    tar xvf ncbi-blast-2.2.31+-x64-linux.tar.gz && \
    mkdir -p /opt/gluetools/blast/ncbi-blast-2.2.31+ && \
    cp -r ncbi-blast-2.2.31+/* /opt/gluetools/blast/ncbi-blast-2.2.31+/ && \
    chmod a+rwx /opt/gluetools/blast/ncbi-blast-2.2.31+/bin/* && \
    mkdir -p /opt/gluetools/blast/ncbi-blast-2.2.31+/blastdbs \
            /opt/gluetools/tmp/blastdbs \
            /opt/gluetools/tmp/blastfiles

# Make sure all required directories exist
RUN mkdir -p /opt/gluetools/tmp/clusterPicker \
            /opt/gluetools/clusterPicker/lib \
            /opt/gluetools/tmp/jmodeltest \
            /opt/gluetools/jModelTest/lib \
            /opt/gluetools/tmp/tbl2asn \
            /opt/gluetools/tbl2asn/bin \
            /opt/gluetools/tmp/sam

# Make gluetools.sh executable
RUN chmod u+x /opt/gluetools/bin/gluetools.sh

# Set environment variables
ENV GLUE_HOME=/opt/gluetools
ENV PATH="${PATH}:${GLUE_HOME}/bin"
ENV LANG=C.UTF-8

# This is exactly what the gluetools.sh script looks for
COPY glue-config.xml /opt/gluetools/conf/gluetools-config.xml

# Copy utility script for user to run
COPY parse_glue_xml.py /opt/gluetools/bin/parse_glue_xml.py
RUN chmod +x /opt/gluetools/bin/parse_glue_xml.py
COPY rabv-genotype-reference.sh /opt/gluetools/bin/rabv-genotype-reference.sh
RUN chmod +x /opt/gluetools/bin/rabv-genotype-reference.sh

# Set working directory
WORKDIR /opt/gluetools/projects