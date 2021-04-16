# Represents docker.io/library/gradle:jdk11-openj9 at 2021-01-14
FROM gradle@sha256:7e07e513b83e6a7790f0cb30820f4142b96ab7ceaac67865965b2127734c2c3d AS java_builder

RUN apt-get update --fix-missing

#---------------------------------------------------------------------------------
# Installing nextflow

ARG NEXTFLOW_REVISION="539a22b68c114c94eaf4a88ea8d26b7bfe2d0c39"

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

ARG R_STATS_C_STREAMER_REVISION="044f967f4d95ecdcff7fa20216342af8dd58f3c1"

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

ARG SUMSTAT_TOOLS_REVISION="6667f58010f3f083c83bf0126b582e9246fe4a42"

COPY sumstat-tools.zip .

# Note: when sumstat-tools becomes a public repository, uncomment these lines and remove the copy above:
#RUN wget "https://github.com/BioPsyk/sumstat-tools/archive/${SUMSTAT_TOOLS_REVISION}.zip" \
# --quiet -O sumstat-tools.zip && \
RUN unzip -q sumstat-tools.zip && \
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
# Compiling b3sum since it is not packaged for debian

# Represents docker.io/library/rust:1.49.0-slim at 2021-01-21
FROM rust@sha256:f46e703b7a0efd836690ed488edc55f8f84f4a161aa9a2724e0cffd59646f5a5 AS rust_builder

RUN cargo install b3sum

#---------------------------------------------------------------------------------
# Creating runtime image with software built in builder image

# Represents docker.io/library/adoptopenjdk:11-jre-openj9 at 2021-01-14
FROM adoptopenjdk@sha256:477d0c53aca999692d2432e529af1f7abd715205fcfc36534ac9ff490f4da0e8

COPY --from=java_builder /cleansumstats /cleansumstats
COPY --from=rust_builder /usr/local/cargo/bin/b3sum /usr/bin/b3sum

WORKDIR /cleansumstats

RUN mv r-stats-c-streamer/build/r-stats-c-streamer /usr/bin/ && \
  rm -rf r-stats-c-streamer

COPY install-sumstat-tools.sh .

RUN mv sumstat-tools /usr/lib/ && \
  ./install-sumstat-tools.sh /usr/lib/sumstat-tools/bin /usr/bin

RUN mv nextflow/build/releases/nextflow-20.10.0-all /usr/bin/nextflow && \
  chmod +x /usr/bin/nextflow

RUN apt-get update --fix-missing && \
  apt-get install python3 python3-pip python gawk graphviz dos2unix pigz -y && \
  pip3 install CrossMap && \
  pip3 install jsonschema && \
  pip3 install pyyaml && \
  apt-get remove --purge python3-pip -y

RUN useradd -rm -s /bin/bash -g users -u 1000 nextflow
RUN rm -rf /cleansumstats/* && chown nextflow:users /cleansumstats && chmod g+s /cleansumstats

COPY ibp-pipeline-lib-0.1.1.jar /cleansumstats/ipb-pipeline-lib.jar

ENV NXF_CLASSPATH="/cleansumstats/ipb-pipeline-lib.jar"

COPY --from=java_builder /cleansumstats/external_data /cleansumstats/external_data
RUN chown nextflow:users /cleansumstats/external_data -R

USER nextflow
