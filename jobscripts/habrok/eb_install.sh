#!/bin/bash

CONTAINER=docker://ghcr.io/bedroge/build-node
REPO=hpc.rug.nl
OS=rocky8

function show_help() {
  echo "
Usage: $0 [OPTION]... <COMMAND>

  -a, --arch <ISA>/<MICROARCHITECTURE>   architecture to build for, e.g. x86_64/haswell
  -b, --bind <DIR1[,DIR2,...,DIRN]>      bind the given host directory into the build container
  -h, --help                             display this help and exit
  -k, --keep                             keep this run's temporary directory
  -n, --name <FILENAME>                  name of the resulting tarball
  -o, --output <DIRECTORY>               output directory for storing the produced tarball
  -t, --tmpdir <DIRECTORY>               temporary directory to be used for CVMFS, fuse-overlayfs, and EasyBuild
"
}

function cleanup() {
  if [ -z "${NOCLEAN}" ]
  then
    echo "Cleaning up temporary directory ${MYTMPDIR} for this run..."
    rm -rf ${MYTMPDIR}
  else
    echo "Not cleaning up temporary directory ${MYTMPDIR} for this run."
  fi
}

# Parse command-line options

# Option strings
SHORT=h?k?a:b:n:o:t:
LONG=help,keep,arch:bind:name:output:tmpdir:

# read the options
OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")

if [ $? != 0 ] ; then echo "Failed to parse options... exiting." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -h | --help )
      show_help
      exit 0
      ;;
    -k | --keep )
      NOCLEAN=1
      shift
      ;;
    -a | --arch )
      ARCH="$2"
      shift 2
      ;;
    -b | --bind )
      BIND="$2"
      shift 2
      ;;
    -n | --name )
      TARBALL="$2"
      shift 2
      ;;
    -o | --outdir )
      OUTDIR="$2"
      shift 2
      ;;
    -t | --tmpdir )
      TMPDIR="$2"
      shift 2
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

SINGBIND=""
for dir in ${BIND//,/ }
do
    SINGBIND="$SINGBIND -B ${dir}"
done

#ARCH=${ARCH:-$(uname -m)/$(archspec cpu)}
if [ -z "${TMPDIR}" ]
then
  echo 'No temporary directory specified with $TMPDIR nor -t, so using /tmp as base temporary directory.'
  TMPDIR=/tmp
fi
MYTMPDIR=$(mktemp -p ${TMPDIR} -d eb_install.XXXXX)
[ -z ${MYTMPDIR} ] && echo "Failed to create temporary directory!" && exit 1
echo "Using ${MYTMPDIR} as temporary directory for this run."
trap cleanup EXIT

if [ -z "${OUTDIR}" ]
then
  OUTDIR=$PWD
  echo 'No output directory specified. The tarball will be saved to $PWD.'
fi

if [ -z ${ARCH} ];
then
  # No architecture specified, so let's build for the current host.
  # Use archspec to determine the architecture name of this host.
  ARCH=$(uname -m)/$(singularity exec ${CONTAINER} archspec cpu)
  #ARCH=x86_64/zen2
  #export EASYBUILD_OPTARCH="march=x86-64-v3"
elif [ ! -z "${ARCH##*'/'*}" ]
then
  # Architecture was specified, but is invalid.
  echo "Error: invalid architecture. Please use <ISA>/<MICROARCHITECTURE>, e.g. x86_64/haswell."
  exit 1
else
  # Architecture was specified correctly. The Easybuild setting should only contain the last part,
  # e.g. "march=haswell" when "x86_64/haswell" was specified.
  export EASYBUILD_OPTARCH="march=${ARCH#*/}"
fi

echo "Going to build for architecture ${ARCH}."

mkdir -p ${MYTMPDIR}/cvmfs/{lib,run}
mkdir -p ${MYTMPDIR}/overlay/{upper,work}
mkdir -p ${MYTMPDIR}/pycache

# avoid that pyc files for EasyBuild are stored in EasyBuild installation directory
export PYTHONPYCACHEPREFIX=${MYTMPDIR}/pycache

CVMFS_LOCAL_DEFAULTS=${MYTMPDIR}/cvmfs/default.local
echo "ARCH=${ARCH}" > $CVMFS_LOCAL_DEFAULTS
# Use host's proxy if it has one?
#if [ -f /etc/cvmfs/default.local ];
#then
#  cat /etc/cvmfs/default.local | grep -v "^ARCH=" >> $CVMFS_LOCAL_DEFAULTS
#  grep "CVMFS_HTTP_PROXY=" /etc/cvmfs/default.local >> $CVMFS_LOCAL_DEFAULTS
#else
  echo 'CVMFS_HTTP_PROXY=DIRECT' >> ${CVMFS_LOCAL_DEFAULTS}
#fi

# Configure EasyBuild
source eb_configuration
mkdir -p ${EASYBUILD_SOURCEPATH}

# Generate the script that we need to actually build the software.
export COMMAND=$@
TMPSCRIPT=${MYTMPDIR}/eb_install.sh
cat << EOF > $TMPSCRIPT
cd $HOME
# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc
module use /cvmfs/${REPO}/${ARCH}/modules/all
module purge
#export EASYBUILD_INSTALLPATH=/cvmfs/${REPO}/${ARCH}

if ! module is-avail EasyBuild
then
  echo "No Easybuild installation found! Installing it for you..."
  pip3 install --prefix ${MYTMPDIR}/eb_tmp easybuild
  export PATH=${MYTMPDIR}/eb_tmp/bin:$PATH
  PYVER=\$(python3 -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))')
  echo "Found Python \${PYVER}, using this for Easybuild installation"
  export PYTHONPATH=${MYTMPDIR}/eb_tmp/lib/python\${PYVER}/site-packages:$PYTHONPATH
  #export PYTHONPATH=${MYTMPDIR}/eb_tmp/lib/python3.9/site-packages:$PYTHONPATH
  eb --install-latest-eb-release
fi
module load EasyBuild
$COMMAND

# Generate Lmod cache
DOT_LMOD="\${EASYBUILD_INSTALLPATH}/.lmod"
LMOD_RC="\${DOT_LMOD}/lmodrc.lua"
if [ ! -d "\${DOT_LMOD}" ]
then
  mkdir -p "\${DOT_LMOD}/cache"
fi

if [ ! -f "\${LMOD_RC}" ]
then
  cat > "\${LMOD_RC}" <<LMODRCEOF
propT = {
}
scDescriptT = {
    {
        ["dir"] = "\${DOT_LMOD}/cache",
        ["timestamp"] = "\${DOT_LMOD}/cache/timestamp",
    },
}
LMODRCEOF
fi
/bin/bash -l -c "/usr/share/lmod/lmod/libexec/update_lmod_system_cache_files -d \${DOT_LMOD}/cache -t \${DOT_LMOD}/cache/timestamp \${EASYBUILD_INSTALLPATH}/modules/all"
EOF

# Launch the container. If a command was specified, we run the above script. Otherwise, we fire up an interactive shell.
if [ -z "${COMMAND}" ];
then
  singularity shell ${SINGBIND} -B ${EASYBUILD_SOURCEPATH} -B ${CVMFS_LOCAL_DEFAULTS}:/etc/cvmfs/default.local -B ${MYTMPDIR}/cvmfs/run:/var/run/cvmfs -B ${MYTMPDIR}/cvmfs/lib:/var/lib/cvmfs -B ${MYTMPDIR} --fusemount "container:cvmfs2 ${REPO} /cvmfs_ro/${REPO}" --fusemount "container:fuse-overlayfs -o lowerdir=/cvmfs_ro/${REPO} -o upperdir=${MYTMPDIR}/overlay/upper -o workdir=${MYTMPDIR}/overlay/work /cvmfs/${REPO}" ${CONTAINER}
else
  singularity shell ${SINGBIND} -B ${EASYBUILD_SOURCEPATH} -B ${CVMFS_LOCAL_DEFAULTS}:/etc/cvmfs/default.local -B ${MYTMPDIR}/cvmfs/run:/var/run/cvmfs -B ${MYTMPDIR}/cvmfs/lib:/var/lib/cvmfs -B ${MYTMPDIR} --fusemount "container:cvmfs2 ${REPO} /cvmfs_ro/${REPO}" --fusemount "container:fuse-overlayfs -o lowerdir=/cvmfs_ro/${REPO} -o upperdir=${MYTMPDIR}/overlay/upper -o workdir=${MYTMPDIR}/overlay/work /cvmfs/${REPO}" ${CONTAINER} < $TMPSCRIPT
fi

# Make a tarball of the installed software if the overlay's upper dir is non-empty.
OLDPWD=$PWD
UPPERARCHDIR=${MYTMPDIR}/overlay/upper/${ARCH%/*}
CPUARCH=${ARCH#*/}
if [ -d ${UPPERARCHDIR} ] && [ "$(ls -A ${UPPERARCHDIR})" ]
then
  TARBALL=${OUTDIR}/${TARBALL:-${ARCH#*/}-$(date +%s).tar.gz}
  FILES_LIST=${MYTMPDIR}/files.list.txt
  cd ${UPPERARCHDIR}

  if [ -d ${CPUARCH}/.lmod ]; then
    # include Lmod cache and configuration file (lmodrc.lua),
    # skip whiteout files and backup copies of Lmod cache (spiderT.old.*)
    find ${CPUARCH}/.lmod -type f | egrep -v '/\.wh\.|spiderT.old' > ${FILES_LIST}
  fi
  if [ -d ${CPUARCH}/modules ]; then
    # module files
    find ${CPUARCH}/modules -type f >> ${FILES_LIST}
    # module symlinks
    find ${CPUARCH}/modules -type l >> ${FILES_LIST}
  fi
  if [ -d ${CPUARCH}/software ]; then
    # installation directories
    ls -d ${CPUARCH}/software/*/* >> ${FILES_LIST}
  fi

  echo "Creating tarball ${TARBALL}..."
  cd $OLDPWD
  tar -C ${UPPERARCHDIR} -czf ${TARBALL} --files-from=${FILES_LIST} --exclude=*.wh.*
else
  echo "Looks like no software has been installed, so not creating a tarball."
fi
