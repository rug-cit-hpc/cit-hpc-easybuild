# Habrok EasyBuild scripts

This directory contains the scripts to be used for building software on Habrok using EasyBuild.

## `eb_install.sh`
The `eb_install.sh` command allows you to run EasyBuild (or any other command) in the Singularity build container based on Rocky Linux 8.
It will automatically mount the CVMFS repository inside the container, and it uses `fuse-overlayfs` to write changes to `/cvmfs` to
a temporary directory on the host. If specified, a tarball containing all changes (e.g. all software that you installed) can be automatically created.
This tarball can then be ingested on the CVMFS publisher node.

The script uses the following syntax:

```
Usage: eb_install.sh [OPTION]... [<COMMAND>]
  -a, --arch <ISA>/<VENDOR>/<uarch>      architecture to build for, e.g. x86_64/intel/haswell or x86_64/generic
  -b, --bind <DIR1[,DIR2,...,DIRN]>      bind the given host directory into the build container
  -h, --help                             display this help and exit
  -k, --keep                             keep this run's temporary directory
  -n, --name <FILENAME>                  name of the resulting tarball
  -o, --output <DIRECTORY>               output directory for storing the produced tarball, no tarball is created when not set
  -t, --tmpdir <DIRECTORY>               temporary directory to be used for CVMFS, fuse-overlayfs, and EasyBuild
```

If no `COMMAND` is specified, the script will launch an interactive container session.


## `eb_configuration`
This file contains the EasyBuild configuration used by `eb_install.sh`. Note that environment variables are being used in order to allow
`eb_install.sh` to source this file. This also makes it possible to use other environment variables like `$HOME` and `$USER` in the configuration.
