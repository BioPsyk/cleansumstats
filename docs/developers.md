# Developer instructions

Here we collect developer specific documentation, which never should be of interest of a user

## Creating the ibp-pipeline-lib .jar file
Build the ibp-pipeline-lib-x.x.x.jar file accroding to instructions at: https://github.com/BioPsyk/ibp-pipeline-lib, Then place it inside the docker/ directory in the cleansumstats repository to be accessible by the docker build script. To facilitate development and because of the small size of the image, we have decided to store the correct version for this repo in the docker/ directory. If in the future this file becomes too large we might exclude it from the repo.


