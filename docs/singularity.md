# Singularity instructions

This repository uses Docker to build it's container image, which is then converted
to a Singularity image so that it can be used on HPC clusters that doesn't have
Docker available.

The reason why Docker images are built and then converted to singularity images
is to leverage Docker's layer caching for faster rebuilds during development.

## Running commands

In order to run commands inside singularity you use the script
`scripts/singularity-run.sh`. This script works exactly the same way as
`scripts/docker-run.sh` except that it runs the command using singularity
instead of Docker.

In order to use this script you need to build the Docker image first,
please see [Docker instructions](docker.md) for details.

Here's an example of how you run all the automated tests using singularity:

```bash
./scripts/singularity-run.sh /cleansumstats/tests/run-tests.sh
```

## Starting a shell

In order the start a shell inside the container you use the script
`scripts/singularity-shell.sh`. This script works exactly the same way as
`scripts/docker-shell.sh` except that it runs the command using singularity
instead of Docker.
