# Stick to old version of fuse-overlayfs due to issues with newer versions
# (cfr. https://github.com/containers/fuse-overlayfs/issues/232)
ARG fuseoverlayfsversion=0.3
ARG fqrn=hpc.rug.nl


FROM rockylinux/rockylinux:8 AS build-fuse-overlayfs
ARG fuseoverlayfsversion
RUN dnf install -y wget fuse3-devel autoconf automake gcc-c++ make tar gzip
RUN wget https://github.com/containers/fuse-overlayfs/archive/refs/tags/v${fuseoverlayfsversion}.tar.gz \
  && tar xzf v${fuseoverlayfsversion}.tar.gz \
  && cd fuse-overlayfs-${fuseoverlayfsversion} \
  && ./autogen.sh && ./configure && make && make install


FROM rockylinux/rockylinux:8
ARG fqrn

COPY --from=build-fuse-overlayfs /usr/local/bin/fuse-overlayfs /usr/local/bin/fuse-overlayfs
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
    dnf install -y python39 python39-setuptools python39-pip python39-cryptography python39-pyyaml python39-wheel && \
    dnf install -y glibc-gconv-extra which make libtool automake autoconf file bzip2 gzip p7zip p7zip-plugins && \
    dnf install -y openssl openssl-devel openssh-clients strace wget curl && \
    dnf install -y vim-common xz unzip zip && \
    pip3 install pep8
# Easybuild GitHub integration
RUN pip3 install GitPython keyring keyrings.alt rich
# Install archspec for CPU detection
RUN pip3 install archspec

RUN mkdir -p /cvmfs/${fqrn} && mkdir -p /cvmfs_ro/${fqrn}

# CVMFS config. TODO: use wget from git repo? install package? manually copy files?
#echo 'CVMFS_HTTP_PROXY=DIRECT'
RUN mkdir /etc/cvmfs/keys/${fqrn#*"."} && \
    echo "CVMFS_SERVER_URL=http://195.169.22.138/cvmfs/@fqrn@" > /etc/cvmfs/domain.d/${fqrn#*"."}.conf && \
    echo "CVMFS_KEYS_DIR=/etc/cvmfs/keys/${fqrn#*'.'}" >> /etc/cvmfs/domain.d/${fqrn#*"."}.conf && \
    echo -e '-----BEGIN PUBLIC KEY-----\n\
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuoMUe5DnEp59xZ5f++aA\n\
VALX/N9GcM43uVxVDqm4WYnT0ZdNeW0vmnCGVx1I3jJKVK4304OZOO1ZBYjH7cyD\n\
RmE/PvMlqSdbPjNQoPJi5owSYG2jO+FRf67xGY0vQf7/hN+dy2FyVZ50X/JQMavw\n\
yzAiKO0sRxao7yCV/n4RNaLbdY4LEivc8IKAqq5IQgCQTSX8LdOb2MHKkQvOJzQ9\n\
ZF+YuqdWdcAalDqDEoridDVAaDqqcMqRcRIrXoDU6CR365ebLT6L+LfcLDfIrxVl\n\
1MhoMZAgI02SB4fIYBXh1xmjdomWuDp23OHJjko+PCj5PGjJQ/SL4ZHcKIkiCmWM\n\
JQIDAQAB\n\
-----END PUBLIC KEY-----\n' > /etc/cvmfs/keys/${fqrn#*"."}/${fqrn#*"."}.pub
