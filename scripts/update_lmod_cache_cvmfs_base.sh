#!/bin/bash

source $(dirname $(realpath $0))/stack.cfg

CONTAINER="docker://ghcr.io/rug-cit-hpc/build-node:${os}"

# Generate base module cache
DOT_LMOD="${stack_base_std}/.lmod"
LMOD_RC="${stack_base_std}/.lmod/lmodrc.lua"

apptainer shell -B /cvmfs ${CONTAINER} <<EOF
modulefiles=\$(find ${stack_base_std}/modules -name "*.lua" | grep -v StdEnv)
for modulefile in \${modulefiles}
do
  echo \${modulefile}
done

if [ ! -d "${DOT_LMOD}" ]
then
  mkdir -p "${DOT_LMOD}/cache"
fi

if [ ! -f "${LMOD_RC}" ]
then
  cat > "${LMOD_RC}" <<LMODRCEOF
propT = {
}
scDescriptT = {
    {
        ["dir"] = "${DOT_LMOD}/cache",
        ["timestamp"] = "${DOT_LMOD}/cache/timestamp",
    },
}
LMODRCEOF
fi

ls ${stack_base_std}/modules
MODULEPATH=${stack_base_std}/modules
echo "Using MODULEPATH: \${MODULEPATH}"
/usr/share/lmod/lmod/libexec/update_lmod_system_cache_files -d ${DOT_LMOD}/cache -t ${DOT_LMOD}/cache/timestamp \$MODULEPATH

EOF
