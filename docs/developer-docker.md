# Docker instructions

This repository contains a `Dockerfile` that can be used to build a Docker image
that contains the latest release of nextflow and all the tools
(internal and 3rd party) needed to run the `cleansumstats` pipeline.

Both nextflow and all internal tools are built from source during Docker image
creation. [Docker multi-staged build](https://docs.docker.com/develop/develop-images/multistage-build/)
is used to create a final runtime Docker image that only contains runtime dependencies.

Note that singularity can be used as container runtime instead of Docker, please
see [Singularity instructions](singularity.md) for details.

## Building the Docker image

There are 2 internal tools/libraries that are included in the Docker image:

- [r-stats-c-streamer](https://github.com/pappewaio/r-stats-c-streamer)
- [sumstat-tools](https://github.com/BioPsyk/sumstat-tools)
- [ibp-pipeline-lib](https://github.com/BioPsyk/ibp-pipeline-lib)

`r-stats-c-streamer` is kept in a public GitHub repository, so it can be automatically
downloaded and built inside the Docker image. `sumstat-tools` however, is kept in a
private GitHub repository, which means one must download the zip-archive manually and
save it in the `docker/` directory of this repository before building the Docker image.

Here's a direct link to the zip-archive:
[sumstat-tools.zip](https://github.com/BioPsyk/sumstat-tools/archive/6667f58010f3f083c83bf0126b582e9246fe4a42.zip).
Download that file and save it with the file name `docker/sumstat-tools.zip` in this
repository. When this repository becomes public, there will be no need to download the zip.

After doing that you can start the Docker image build:

```bash
./scripts/docker-build.sh
```

That will build the Docker image and tag using the identifier `ibp-cleansumstats:latest`.

## Running commands

In order to run commands inside the Docker container you use the script
`scripts/docker-run.sh`. This script takes care of mounting all files/directories
from the repository into the container needed to run the pipeline. It also takes
all arguments given to it and passes them on to the actual `docker run` command.

All the mounted files/directories uses the base path `/cleansumstats` inside
the container. If you for example want to run all the automated tests, which
is done by running the script `tests/run-tests.sh`, you have to apply the
base path to that path:

```bash
./scripts/docker-run.sh /cleansumstats/tests/run-tests.sh
```

## Starting a shell

In order the start a shell inside the container you use the script
`scripts/docker-shell.sh`. This script takes care of mounting all
files/directories needed, just like `scripts/docker-run.sh`.
