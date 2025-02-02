FROM gradle:8.5-jdk11 AS java_builder

RUN apt-get update --fix-missing

#---------------------------------------------------------------------------------
# Installing nextflow

ARG NEXTFLOW_REVISION="v24.10.4"

WORKDIR /cleansumstats

RUN wget "https://github.com/nextflow-io/nextflow/archive/${NEXTFLOW_REVISION}.zip" \
  --quiet -O nextflow.zip && \
  unzip -q nextflow.zip && \
  mv "nextflow-${NEXTFLOW_REVISION#v}" "nextflow" && \
  rm nextflow.zip

WORKDIR /cleansumstats/nextflow

RUN gradle --daemon && BUILD_PACK=1 gradle compile pack

WORKDIR /cleansumstats

#---------------------------------------------------------------------------------
# Installing rmath

RUN apt-get update --fix-missing -y && apt-get install -y cmake build-essential

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

ARG R_STATS_C_STREAMER_REVISION="cdd497488f1dd8c5a33cf5da27fe6af86c5b7c11"

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


COPY --from=java_builder /cleansumstats /cleansumstats
COPY --from=rust_builder /usr/local/cargo/bin/b3sum /usr/bin/b3sum


WORKDIR /cleansumstats

RUN mv r-stats-c-streamer/build/r-stats-c-streamer /usr/bin/ && \
  rm -rf r-stats-c-streamer

COPY install-sumstat-tools.sh .

RUN mv sumstat-tools /usr/lib/ && \
  ./install-sumstat-tools.sh /usr/lib/sumstat-tools/bin /usr/bin

# Create /usr/bin directory first and then move the nextflow executable
RUN mkdir -p /usr/bin && \
    ls -la nextflow/build/ || true && \
    ls -la nextflow/build/releases/ || true && \
    find nextflow/build -name "nextflow-*" -type f && \
    mv nextflow/build/releases/nextflow-24.10.4-dist /usr/bin/nextflow && \
    chmod +x /usr/bin/nextflow

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

# Verify CrossMap installation and location
#RUN which CrossMap.py && \
#    ls -l /usr/local/bin/CrossMap.py && \
#    ls -l /usr/bin/CrossMap.py && \
#    ls -l /opt/venv/bin/CrossMap.py

# Use existing ubuntu user and group
RUN rm -rf /cleansumstats/* && chown ubuntu:ubuntu /cleansumstats && chmod g+s /cleansumstats

COPY --from=java_builder /cleansumstats/external_data /cleansumstats/external_data
RUN chown ubuntu:ubuntu /cleansumstats/external_data -R

USER ubuntu
