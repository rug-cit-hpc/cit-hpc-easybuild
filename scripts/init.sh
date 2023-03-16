#!/bin/bash

#
# Set up the directory structure for a (new) stack.
#

source $(dirname $(realpath $0))/stack.cfg

for genarch in ${generic_architectures}; do
    echo "Creating ${stack_base}/${genarch}..."
    mkdir -p ${stack_base}/${genarch}/modules
    mkdir -p ${stack_base}/${genarch}/software
done

for arch in ${architectures}; do
    echo "Creating ${stack_base}/${arch}..."
    mkdir -p ${stack_base}/${arch}/modules
    mkdir -p ${stack_base}/${arch}/software
done

