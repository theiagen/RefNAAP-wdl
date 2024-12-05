# Software installation, no database files
FROM condaforge/miniforge3:23.3.1-1

# build and run as root users since micromamba image has 'mambauser' set as the $USER
USER root
# set workdir to default for building; set to /data at the end
WORKDIR /

# Version arguments
# ARG variables only persist during build time
# using latest commit as of 2021/04/29
ARG REFNAAP_COMMIT="b3ad097443233e191d6a211bdbd851583f1ba6ae"
ARG REFNAAP_SRC_URL=https://github.com/jiangweiyao/RefNAAP/archive/${REFNAAP_COMMIT}.zip

# metadata labels
LABEL base.image="condaforge/miniforge3:23.3.1-1"
LABEL dockerfile.version="1"
LABEL software="RefNAAP-wdl"
LABEL software.version=${REFNAAP_COMMIT}
LABEL description="A WDL wrapper of jiangweiyao/RefNAAP for Terra.bio"
LABEL website="https://github.com/jiangweiyao/RefNAAP"
LABEL maintainer1="Inês Mendes"
LABEL maintainer.email1="ines.mendes@theiagen.com"

# install dependencies; cleanup apt garbage
RUN apt-get update && apt-get install -y --no-install-recommends \
  wget \
  ca-certificates \
  git \
  libtiff5 \
  unzip \
  bsdmainutils \
  gcc && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/*

# get the RefNAAP latest release
RUN wget --quiet "${REFNAAP_SRC_URL}" && \
 unzip ${REFNAAP_COMMIT}.zip && \
 rm ${REFNAAP_COMMIT}.zip && \
 mv -v RefNAAP-${REFNAAP_COMMIT} RefNAAP

# update environment.yml to include the latest fastQC version
RUN sed -i 's/fastqc=0.11.9/fastqc=0.12.1/g' RefNAAP/environment.yml

# install environment.yml from RefNAAP repo
RUN mamba env create -f RefNAAP/environment.yml && \
  mamba clean --all -y

# set the environment, add base conda/micromamba bin directory into path
# set locale settings to UTF-8
# set the environment, put new conda env in PATH by default
ENV PATH="/opt/conda/bin:${PATH}" \
  LC_ALL=C.UTF-8nt
ENV PATH="/opt/conda/envs/refnaap/bin:${PATH}"

# add RefNAAP to PATH
ENV PATH="/RefNAAP:${PATH}"

# set final working directory to /data
WORKDIR /data