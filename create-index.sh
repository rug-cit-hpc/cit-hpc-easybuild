#!/bin/bash
module load EasyBuild

eb --force --index-max-age=0 --create-index $HOME/easybuild/easybuild-easyconfigs/easybuild/easyconfigs
eb --force --index-max-age=0 --create-index $HOME/easybuild/cit-hpc-easybuild/easyconfigs

