#!/bin/bash

source $(dirname $(realpath $0))/stack.cfg

CONTAINER="docker://ghcr.io/rug-cit-hpc/build-node:${os}"

for arch in ${architectures}
do
  STACK=${stack_base_nfs}/${arch}
  DOT_LMOD="${STACK}/.lmod"
  LMOD_RC="${STACK}/.lmod/lmodrc.lua"

  echo "Generating Lmod cache for ${STACK}..."

  apptainer shell -B /apps -B /cvmfs ${CONTAINER} <<EOF

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

ls ${STACK}/modules
unset MODULEPATH
for class in \$(ls -1 ${STACK}/modules | grep -v "^all$");
do
  if [ -z \${MODULEPATH} ]; then
    export MODULEPATH=${STACK}/modules/\${class}
  else
    export MODULEPATH=\${MODULEPATH}:${STACK}/modules/\${class}
  fi
done
echo "Using MODULEPATH: \${MODULEPATH}"
/usr/share/lmod/lmod/libexec/update_lmod_system_cache_files -d ${DOT_LMOD}/cache -t ${DOT_LMOD}/cache/timestamp \$MODULEPATH
#${STACK}/modules/all

EOF

done
