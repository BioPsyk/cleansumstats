FROM gradle:8.5-jdk11 AS java_builder

RUN apt-get update --fix-missing

#---------------------------------------------------------------------------------
# Installing nextflow using pre-built binary

ARG NEXTFLOW_VERSION="24.10.4"

WORKDIR /cleansumstats

# Download and install Nextflow standalone distribution
RUN curl -fsSL https://github.com/nextflow-io/nextflow/releases/download/v24.10.4/nextflow-24.10.4-dist > /usr/local/bin/nextflow && \
    chmod +x /usr/local/bin/nextflow && \
    # Pre-download basic plugin dependencies
    nextflow plugin install nf-validation

# Create nextflow cache directory
RUN mkdir -p /root/.nextflow

# Ensure the cache is preserved in the final image
VOLUME /root/.nextflow

#---------------------------------------------------------------------------------
# Installing rmath
# Retry mechanism for apt-get to handle temporary network issues
# Installs cmake and build-essential required for building rmath
RUN apt-get update --fix-missing -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      cmake \
      build-essential \
      wget \
      unzip \
      --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

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

ARG R_STATS_C_STREAMER_REVISION="e56512fb9b3161a4a43a1f0c26147eb8d299730b"

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
# Downloading liftOver chain files

ENV HG_URL="https://hgdownload.cse.ucsc.edu/goldenpath"
ENV HG_38_19_CHECKSUM="14a712e8e147d9fc8e9d87d51977b46f6f8ddb93efbe5d0843d86b6205f587b1"
ENV HG_19_17_CHECKSUM="8cf79945bf5d65342568ee1007bcb427fe7fc7b6fe0168401d452a82d5e129a2"
ENV HG_19_18_CHECKSUM="fc312e924e970dee936a69972768c6f84591d3a6daddbe598e49321c5fb1d253"

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
# Installing sumstat-tools

ARG SUMSTAT_TOOLS_REVISION="83d25a5b23ce938eeeff78354fc7544e113d31a0"

RUN wget "https://github.com/BioPsyk/sumstat-tools/archive/${SUMSTAT_TOOLS_REVISION}.zip" \
  --quiet -O sumstat-tools.zip && \
  unzip -q sumstat-tools.zip && \
  mv "sumstat-tools-${SUMSTAT_TOOLS_REVISION}" sumstat-tools && \
  rm sumstat-tools.zip

#---------------------------------------------------------------------------------
# Compiling b3sum since it is not packaged for debian
FROM rust:1.84-slim-bookworm AS rust_builder

RUN cargo install --version 0.3.8 b3sum

#---------------------------------------------------------------------------------
# Creating runtime image with software built in builder image
FROM eclipse-temurin:11

COPY --from=java_builder /usr/local/bin/nextflow /usr/local/bin/nextflow
COPY --from=java_builder /cleansumstats /cleansumstats
COPY --from=rust_builder /usr/local/cargo/bin/b3sum /usr/bin/b3sum

WORKDIR /cleansumstats

RUN mv r-stats-c-streamer/build/r-stats-c-streamer /usr/bin/ && \
  rm -rf r-stats-c-streamer

COPY install-sumstat-tools.sh .

RUN mv sumstat-tools /usr/lib/ && \
  ./install-sumstat-tools.sh /usr/lib/sumstat-tools/bin /usr/bin

# Create a virtual environment for Python packages
RUN apt-get update --fix-missing && \
    apt-get install python3 python3-pip python3-venv gawk graphviz dos2unix pigz \
    libbz2-dev liblzma-dev vim -y && \
    python3 -m venv /opt/venv

# Make sure we use the virtualenv and make it available system-wide
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

# Install Python packages in the virtualenv
RUN pip3 install --no-cache-dir CrossMap jsonschema pyyaml && \
    apt-get remove --purge python3-pip -y && \
    ln -sf /opt/venv/bin/CrossMap /usr/local/bin/CrossMap.py && \
    ln -sf /opt/venv/bin/CrossMap /usr/bin/CrossMap.py && \
    chmod +x /opt/venv/bin/CrossMap

# Create ubuntu user and group if they don't exist
#RUN groupadd -r ubuntu && useradd -r -g ubuntu ubuntu

# Set up directories with correct permissions
RUN rm -rf /cleansumstats/* && \
    mkdir -p /cleansumstats/.nextflow && \
    chown -R ubuntu:ubuntu /cleansumstats && \
    chmod -R 777 /cleansumstats && \
    chmod g+s /cleansumstats

COPY --from=java_builder /cleansumstats/external_data /cleansumstats/external_data
RUN chown -R ubuntu:ubuntu /cleansumstats/external_data

# Copy lib files
COPY lib/ /cleansumstats/lib/

# Download additional library dependencies
RUN mkdir -p /cleansumstats/lib && \
    cd /cleansumstats/lib && \
    wget -q https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar && \
    wget -q https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.13.5/jackson-annotations-2.13.5.jar && \
    wget -q https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.13.5/jackson-core-2.13.5.jar && \
    wget -q https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.13.5/jackson-databind-2.13.5.jar && \
    wget -q https://repo1.maven.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.13.5/jackson-dataformat-yaml-2.13.5.jar && \
    wget -q https://repo1.maven.org/maven2/com/networknt/json-schema-validator/1.0.87/json-schema-validator-1.0.87.jar


# Then set nextflow for offline mode
ENV NXF_OFFLINE=true

USER ubuntu


## Initialize Nextflow in the final image
#RUN nextflow -version && \
#    nextflow info && \
#    # Run a simple workflow to ensure dependencies are downloaded
#    echo "workflow { println 'Hello' }" > test.nf && \
#    nextflow run test.nf && \
#    rm test.nf
