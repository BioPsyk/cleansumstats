# Represents docker.io/library/gradle:jdk11-openj9 at 2021-01-14
FROM gradle@sha256:7e07e513b83e6a7790f0cb30820f4142b96ab7ceaac67865965b2127734c2c3d AS java_builder

RUN apt-get update --fix-missing

#---------------------------------------------------------------------------------
# Installing nextflow

ARG NEXTFLOW_REVISION="a96233af6fb505a1716a70408d46218f7d45dc96"

WORKDIR /cleansumstats

RUN wget "https://github.com/nextflow-io/nextflow/archive/${NEXTFLOW_REVISION}.zip" \
  --quiet -O nextflow.zip && \
  unzip -q nextflow.zip && \
  mv "nextflow-${NEXTFLOW_REVISION}" "nextflow" && \
  rm nextflow.zip

WORKDIR /cleansumstats/nextflow

RUN apt-get install -y patch
COPY patches/json-schema-dependency.patch json-schema-dependency.patch
RUN patch -p1 < json-schema-dependency.patch

RUN gradle --daemon && BUILD_PACK=1 gradle compile packAll

WORKDIR /cleansumstats

#---------------------------------------------------------------------------------
# Installing rmath

RUN apt-get install -y cmake build-essential

ARG RMATH_REVISION="d816ef8d1719810288afd848e18b2a8d00c2ccd2"

RUN wget "https://github.com/statslabs/rmath/archive/${RMATH_REVISION}.zip" \
  --quiet -O rmath.zip && \
  unzip -q rmath.zip && \
  mv "rmath-${RMATH_REVISION}" "rmath" && \
  rm rmath.zip

WORKDIR /cleansumstats/rmath

RUN mkdir -p build && \
  cd build && \
  cmake .. && \
  make && \
  make install

WORKDIR /cleansumstats

RUN rm -rf rmath

#---------------------------------------------------------------------------------
# Installing r-stats-c-streamer

ARG R_STATS_C_STREAMER_REVISION="a3ef08bef1e45c9135400b42aea798e3bf0dbf0f"

RUN wget "https://github.com/pappewaio/r-stats-c-streamer/archive/${R_STATS_C_STREAMER_REVISION}.zip" \
  --quiet -O r-stats-c-streamer.zip && \
  unzip -q r-stats-c-streamer.zip && \
  mv "r-stats-c-streamer-${R_STATS_C_STREAMER_REVISION}" "r-stats-c-streamer" && \
  rm r-stats-c-streamer.zip

WORKDIR /cleansumstats/r-stats-c-streamer

RUN mkdir -p build && \
  cd build && \
  cmake .. && \
  make

WORKDIR /cleansumstats

#---------------------------------------------------------------------------------
# Installing sumstat-tools

ARG SUMSTAT_TOOLS_REVISION="be12f3b9dea0dbf454a94d7e917e12462acaad11"

RUN wget "https://github.com/BioPsyk/sumstat-tools/archive/${SUMSTAT_TOOLS_REVISION}.zip" \
  --quiet -O sumstat-tools.zip && \
  unzip -q sumstat-tools.zip && \
  mv "sumstat-tools-${SUMSTAT_TOOLS_REVISION}" sumstat-tools && \
  rm sumstat-tools.zip

#---------------------------------------------------------------------------------
# Downloading liftOver chain files

ENV HG_URL "https://hgdownload.cse.ucsc.edu/goldenpath"
ENV HG_38_19_CHECKSUM "14a712e8e147d9fc8e9d87d51977b46f6f8ddb93efbe5d0843d86b6205f587b1"
ENV HG_19_17_CHECKSUM "8cf79945bf5d65342568ee1007bcb427fe7fc7b6fe0168401d452a82d5e129a2"
ENV HG_19_18_CHECKSUM "fc312e924e970dee936a69972768c6f84591d3a6daddbe598e49321c5fb1d253"

RUN mkdir -p external_data/chain_files && \
  cd external_data && \
  wget -P chain_files "${HG_URL}/hg38/liftOver/hg38ToHg19.over.chain.gz" && \
  wget -P chain_files "${HG_URL}/hg19/liftOver/hg19ToHg17.over.chain.gz" && \
  wget -P chain_files "${HG_URL}/hg19/liftOver/hg19ToHg18.over.chain.gz" && \
  cd chain_files && \
  echo "${HG_38_19_CHECKSUM}  hg38ToHg19.over.chain.gz" | sha256sum -c && \
  echo "${HG_19_17_CHECKSUM}  hg19ToHg17.over.chain.gz" | sha256sum -c && \
  echo "${HG_19_18_CHECKSUM}  hg19ToHg18.over.chain.gz" | sha256sum -c

#---------------------------------------------------------------------------------
# Installing htslib, samtools and bcftools

ARG HTSLIB_VERSION="1.9"
ARG BCFTOOLS_VERSION="1.9"
ARG SAMTOOLS_VERSION="1.3.1"

RUN apt-get update --fix-missing
RUN apt-get install -y autoconf automake make zlib1g-dev libbz2-dev \
  liblzma-dev libcurl4-gnutls-dev libssl-dev libncurses5-dev

WORKDIR /cleansumstats

RUN wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 \
  --quiet -O htslib.tar.bz2 && \
  tar -xjvf htslib.tar.bz2 && \
  mv "htslib-${HTSLIB_VERSION}" "htslib"

WORKDIR /cleansumstats/htslib
RUN make
RUN make install

WORKDIR /cleansumstats

RUN wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 \
  --quiet -O samtools.tar.bz2 && \
  tar -vxjf samtools.tar.bz2 && \
  mv "samtools-${SAMTOOLS_VERSION}" "samtools"

WORKDIR /cleansumstats/samtools
RUN make

WORKDIR /cleansumstats

RUN wget https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2 \
  --quiet -O bcftools.tar.bz2 && \
  tar -vxjf bcftools.tar.bz2 && \
  mv "bcftools-${BCFTOOLS_VERSION}" "bcftools"

WORKDIR /cleansumstats/bcftools
RUN make

WORKDIR /cleansumstats

#---------------------------------------------------------------------------------
# Downloading fasta reference for GRCh38 and GRCh37 (suboptimal to have them in image, because of size ~1G each, but now it is like this for simplicity)
# Use samtools to make fasta index (requires samtools to already be installed)
# https://www.ncbi.nlm.nih.gov/genome/guide/human/

#ENV HG_38_FASTA_CHECKSUM "4ef2a29c6425b2b99086aac23d70194704ec67b3ade730d40d96a831e9740777"
#ENV HG_37_FASTA_CHECKSUM "190f35a382668f0e0280539657cbb20ae1182fc71ddb97914185ef2a18eacbea"
#
#RUN mkdir -p external_data/fasta_reference && \
#  cd external_data && \
#  wget -qP fasta_reference "https://ftp.ncbi.nlm.nih.gov/refseq/H_sapiens/annotation/GRCh38_latest/refseq_identifiers/GRCh38_latest_genomic.fna.gz" && \
#  wget -qP fasta_reference "https://ftp.ncbi.nlm.nih.gov/refseq/H_sapiens/annotation/GRCh37_latest/refseq_identifiers/GRCh37_latest_genomic.fna.gz" && \
#  cd fasta_reference && \
#  echo "${HG_38_FASTA_CHECKSUM}  GRCh38_latest_genomic.fna.gz" | sha256sum -c && \
#  echo "${HG_37_FASTA_CHECKSUM}  GRCh37_latest_genomic.fna.gz" | sha256sum -c
#
## Recompress using bgzip and make indices .fai and .gzi (compressed version)
#WORKDIR /cleansumstats/external_data/fasta_reference
#
#RUN zcat GRCh38_latest_genomic.fna.gz | bgzip -c > GRCh38_latest_genomic.fna.bgz && \
#  zcat GRCh37_latest_genomic.fna.gz | bgzip -c > GRCh37_latest_genomic.fna.bgz && \
#  /cleansumstats/samtools/samtools faidx GRCh38_latest_genomic.fna.bgz && \
#  /cleansumstats/samtools/samtools faidx GRCh37_latest_genomic.fna.bgz
#
## Remove the pure gz files to save space
#RUN rm GRCh38_latest_genomic.fna.gz && \
#  rm GRCh37_latest_genomic.fna.gz
#
#WORKDIR /cleansumstats

#---------------------------------------------------------------------------------
# Compiling b3sum since it is not packaged for debian

# Represents docker.io/library/rust:1.49.0-slim at 2021-01-21
FROM rust@sha256:f46e703b7a0efd836690ed488edc55f8f84f4a161aa9a2724e0cffd59646f5a5 AS rust_builder

RUN cargo install --version 0.3.8 b3sum

#---------------------------------------------------------------------------------
# Creating runtime image with software built in builder image

# Represents docker.io/library/adoptopenjdk:11-jre-openj9 at 2021-01-14
FROM adoptopenjdk@sha256:477d0c53aca999692d2432e529af1f7abd715205fcfc36534ac9ff490f4da0e8

COPY --from=java_builder /cleansumstats /cleansumstats
COPY --from=rust_builder /usr/local/cargo/bin/b3sum /usr/bin/b3sum

WORKDIR /cleansumstats

RUN mv /cleansumstats/htslib/tabix /usr/bin/tabix
RUN mv /cleansumstats/htslib/bgzip /usr/bin/bgzip
RUN mv /cleansumstats/samtools/samtools /usr/bin/samtools
RUN mv /cleansumstats/bcftools/bcftools /usr/bin/bcftools

RUN mv r-stats-c-streamer/build/r-stats-c-streamer /usr/bin/ && \
  rm -rf r-stats-c-streamer

COPY install-sumstat-tools.sh .

RUN mv sumstat-tools /usr/lib/ && \
  ./install-sumstat-tools.sh /usr/lib/sumstat-tools/bin /usr/bin

RUN mv nextflow/build/releases/nextflow-21.12.1-edge-all /usr/bin/nextflow && \
  chmod +x /usr/bin/nextflow

RUN apt-get update --fix-missing && \
  apt-get install python3 python3-pip python gawk graphviz dos2unix pigz -y && \
  pip3 install CrossMap && \
  pip3 install jsonschema && \
  pip3 install pyyaml && \
  apt-get remove --purge python3-pip -y

RUN apt-get update --fix-missing && \
  apt-get install vim -y

RUN useradd -rm -s /bin/bash -g users -u 1000 nextflow
RUN rm -rf /cleansumstats/* && chown nextflow:users /cleansumstats && chmod g+s /cleansumstats

COPY ibp-pipeline-lib-1.0.0.jar /cleansumstats/ibp-pipeline-lib.jar

ENV NXF_CLASSPATH="/cleansumstats/ibp-pipeline-lib.jar"

COPY --from=java_builder /cleansumstats/external_data /cleansumstats/external_data
RUN chown nextflow:users /cleansumstats/external_data -R

ENV LANG=en_US.UTF-8

USER nextflow
