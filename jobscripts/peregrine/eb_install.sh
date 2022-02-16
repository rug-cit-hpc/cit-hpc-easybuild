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
singularity shell -B /local/tmp -B /software -B /apps -B /data -B /scratch /home/$USER/easybuild/centos7/buildhost.simg  < $TMPSCRIPT
rm $TMPSCRIPT

