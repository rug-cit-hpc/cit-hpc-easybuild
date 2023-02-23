# Habrok EasyBuild scripts

This directory contains the scripts to be used for building software on Habrok using EasyBuild.

## `build_container.sh`
The `build_container.sh` command allows you to run EasyBuild (or any other command) in the Singularity build container based on Rocky Linux 8.
It will automatically mount the CVMFS repository inside the container, and it uses `fuse-overlayfs` to write changes to `/cvmfs` to
a temporary directory on the host. If specified, a tarball containing all changes (e.g. all software that you installed) can be automatically created.
This tarball can then be ingested on the CVMFS publisher node.

The script uses the following syntax:

```
Usage: build_container.sh [OPTION]... [<COMMAND>]
  -a, --arch <ISA>/<VENDOR>/<uarch>      architecture to build for, e.g. x86_64/intel/haswell or x86_64/generic
  -b, --bind <DIR1[,DIR2,...,DIRN]>      bind the given host directory into the build container
  -h, --help                             display this help and exit
  -k, --keep                             keep this run's temporary directory
  -n, --name <FILENAME>                  name of the resulting tarball
  -o, --output <DIRECTORY>               output directory for storing the produced tarball, no tarball is created when not set
  -t, --tmpdir <DIRECTORY>               temporary directory to be used for CVMFS, fuse-overlayfs, and EasyBuild
  -v, --version <VERSION>                version number of the stack to build software for
```

By default, the script will build/optimize the software for the current host, and uses an installation path that reflects its architecture name (determined by using `archspec` or `archdetect`).
The latter can be overridden if necessary with `-a`/`--arch`, and can also be set to a generic build.

If no `COMMAND` is specified, the script will launch an interactive container session.

The `build_container.sh` scripts needs an accompanying `eb_configuration` file containing the EasyBuild configuration. Note that environment variables are being used in order to allow
`build_container.sh` to source this file. This also makes it possible to use other environment variables like `$HOME` and `$USER` in the configuration.


## Automating the installation using the EESSI GitHub Bot

We use the bot developed by EESSI (https://github.com/EESSI/eessi-bot-software-layer) to automate the software installations using pull requests.
These pull requests should add new software to the easystack file found at https://github.com/rug-cit-hpc/cit-hpc-easybuild/blob/master/easystacks/.

### Setting up the bot
First, follow the installation instructions at https://github.com/EESSI/eessi-bot-software-layer. 

TODO: describe configuration, scripts, how to run the scripts
