#!/bin/bash

#
# Create the directory structure for a new generic installation,
# with symlinks in each architecture-specific stack pointing to the
# installation directory in the generic stack.
#
# Usage: mkgeneric.sh <software name> <module class>
#

source $(dirname $(realpath $0))/stack.cfg

if [ $# -ne 2 ]; then
   echo "Supply software name and module class"
   exit -1
fi

software=$1
class=$2

if [ -z ${software} ]; then
   echo "Specify name of software package"
   exit -1
fi

if [ -z ${class} ]; then
   echo "Specify module class of software package"
   exit -1
fi

if [ ! -d ${stack_base_cvmfs}/x86_64/generic/modules/$class ]; then
   echo "Warning: module directory for $class does not exist yet, it will be created."
   #exit -1
   #mkdir -p ${stack_base_cvmfs}/x86_64/generic/modules/$class
fi

for genarch in ${generic_architectures}; do
    echo "Creating software directory for generic software in ${stack_base_cvmfs}/${genarch}/software"
    mkdir -p ${stack_base_cvmfs}/${genarch}/software/${software}

    echo "Creating module paths for generic software in ${stack_base_cvmfs}/${genarch}/modules"
    mkdir -p ${stack_base_cvmfs}/${genarch}/modules/all/${software}
    mkdir -p ${stack_base_cvmfs}/${genarch}/modules/${class}/${software}
done

echo "Linking software directory for each architecture"
for arch in ${architectures}; do
   echo "  ${arch}"
   cd ${stack_base_cvmfs}/${arch}/software
   ln -s ../../../generic/software/${software} .
done

echo "Linking module directories for each architecture"
for arch in ${architectures}; do
   echo "  ${arch}"
   mkdir -p ${stack_base_cvmfs}/${arch}/modules/all
   cd ${stack_base_cvmfs}/${arch}/modules/all
   ln -s ../../../../generic/modules/all/${software} .
   mkdir -p ${stack_base_cvmfs}/${arch}/modules/${class}
   cd ${stack_base_cvmfs}/${arch}/modules/${class}
   ln -s ../../../../generic/modules/${class}/${software} .
done
