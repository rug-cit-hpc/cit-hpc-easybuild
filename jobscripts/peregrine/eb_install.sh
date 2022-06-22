#!/bin/bash
export COMMAND=$@
TMPSCRIPT=$( mktemp /tmp/eb_install.XXXX )
cat << EOF > $TMPSCRIPT
cd $HOME
. .bashrc
unset LD_LIBRARY_PATH
module purge
module load EasyBuild
eb $COMMAND
EOF
SINGOPTS="-B /local/tmp -B /software -B /apps -B /data -B /scratch"
if [ -c /dev/nvidia0 ]; then
    SINGOPTS="--nv $SINGOPTS"
fi
singularity shell $SINGOPTS /home/$USER/easybuild/cit-hpc-easybuild/singularity/centos7/buildhost.simg  < $TMPSCRIPT
ec=$?
rm $TMPSCRIPT
exit $ec
