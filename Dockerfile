FROM nfcore/base:1.7
LABEL authors="Jesper R. Gådin" \
      description="Docker image containing all requirements for nf-core/cleansumstats pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-cleansumstats-1.0dev/bin:$PATH
