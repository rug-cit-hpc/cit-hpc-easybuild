# Dockerfile for Habrok software build container based on Rocky 8

FROM rockylinux/rockylinux:8
ARG fuseoverlayfsversion=1.10
# Configure the repositories
RUN dnf install -y epel-release && \
    dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled powertools
# Lmod and CVMFS
RUN dnf install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm && \
    dnf install -y Lmod && \
    # install el7 fuse3, as the one for el8 is older and doesn't work with fusemount...
    dnf install -y http://mirror.centos.org/centos/7/os/x86_64/Packages/fuse-2.9.2-11.el7.x86_64.rpm \
                   https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/f/fuse3-3.6.1-2.el7.x86_64.rpm \
                   https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/f/fuse3-libs-3.6.1-2.el7.x86_64.rpm && \
    dnf install -y cvmfs cvmfs-fuse3
# Interconnect libraries
RUN dnf install -y rdma-core rdma-core-devel
# Other tools
RUN dnf install -y gcc gcc-c++ gcc-gfortran gdb patch git flex && \
    dnf install -y python3 python3-setuptools python3-pip python3-cryptography python3-pyyaml python3-wheel && \
    dnf install -y glibc-gconv-extra which make libtool automake autoconf file bzip2 gzip p7zip p7zip-plugins && \
    dnf install -y openssl openssl-devel openssh-clients strace wget curl && \
    dnf install -y vim-common xz unzip zip cpio && \
    pip3 install pycodestyle
# Easybuild GitHub integration
RUN pip3 install GitPython keyring keyrings.alt rich
# Install archspec for CPU detection
RUN pip3 install archspec
# Install EESSI's archdetect for CPU detection
RUN wget -O /usr/local/bin/eessi_archdetect.sh https://raw.githubusercontent.com/EESSI/software-layer/main/init/eessi_archdetect.sh && \
    chmod +x /usr/local/bin/eessi_archdetect.sh && \
    mkdir /usr/local/bin/arch_specs && \
    wget -O /usr/local/bin/arch_specs/eessi_arch_x86.spec https://raw.githubusercontent.com/EESSI/software-layer/main/init/arch_specs/eessi_arch_x86.spec
# Install fuse-overlayfs
RUN wget -O /usr/local/bin/fuse-overlayfs https://github.com/containers/fuse-overlayfs/releases/download/v${fuseoverlayfsversion}/fuse-overlayfs-x86_64 && \
    chmod +x /usr/local/bin/fuse-overlayfs

RUN mkdir -p /cvmfs/hpc.rug.nl && mkdir -p /cvmfs_ro/hpc.rug.nl

# Add CVMFS configuration file and public key
RUN mkdir /etc/cvmfs/keys/rug.nl
COPY containers/docker/rocky8/rug.nl.pub /etc/cvmfs/keys/rug.nl/
COPY containers/docker/rocky8/rug.nl.conf /etc/cvmfs/domain.d/

# Lmod settings
COPY containers/docker/rocky8/00-modulepath.sh /etc/profile.d/
COPY containers/docker/rocky8/z01_StdEnv.sh /etc/profile.d/

# Fix for CUDA installation failures
RUN touch /usr/local/cuda
