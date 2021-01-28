This is meant to be a good pointer in the right direction on where and how to install singularity. 

See here for available releases:
https://github.com/hpcng/singularity/releases

**Remember, to do this you need to be a root user in the system.**

```bash
#Get version of interest, and check version specific docs for special installation
VERSION=3.6.2
https://github.com/hpcng/singularity/releases/download/v$VERSION/singularity-$VERSION.tar.gz
tar xvf singularity-$VERSION.tar.gz
cd singularity-$VERSION

#pre requirements as of release 3.6.2 (See the installation instructions of version of interest)
sudo apt-get update && \
  sudo apt-get install -y build-essential \
  libseccomp-dev pkg-config squashfs-tools cryptsetup

#need to install golang as of release 3.6.2
export VERSION=1.13.15 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz && \
  sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz
  
#need to set path for Go as of release 3.6.2
echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
  echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc && \
  source ~/.bashrc

#Skipping an optinal step for Go as of release 3.6.2

#use Go to build from source
mkdir -p ${GOPATH}/src/github.com/sylabs && \
  cd ${GOPATH}/src/github.com/sylabs && \
  git clone https://github.com/sylabs/singularity.git && \
  cd singularity

#check out version of interest
git checkout v3.6.2

#build
 cd ${GOPATH}/src/github.com/sylabs/singularity && \
  ./mconfig && \
  cd ./builddir && \
  make && \
  sudo make install

#And that's it! Now you can check your Singularity version by running:
singularity version
```
