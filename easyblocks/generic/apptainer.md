The apptainer easyblock is used to install software as apptainer containers, with the final module
also defining aliases to run the application as if it were installed directly on the system.

Both the building and the running processes require apptainer to be installed on the system.
This easyblock is a wrapper around the `build_container_image.sh` script. Currently, it is required
for the script to be located in the directory **$HOME/easybuild/scripts**. Therefore, most arguments 
required by the script need to be passed verbatim through the easybuild parameters `installopts`,
as they are passed directly to the script.

The following arguments for **installopts** are required:
 * `-s <filename.dif | <docker_iamge_link>` which represents the source for building the container.
It can be either the name of a .dif file or a hyperlink to an online docker image.
 * `-i <dif | image>` which represents the type of the source. The value dif mean that the local .dif
file provided in the above argument will be searched and used. The value image means the link provided
above will be used to download and build a docker image.

**Mention: the -n and -v arguments are also required by the script, but they should not be provided in
the .eb file, as they are provided by the easyblock.**

Additionally, the following optional **installopts** argument can be provided:
 * `-z <source/path>` which represents the path to be searched for the local file. Only works with the
"-i dif" option. Defaults to the current working directory.


Apart from the arguments passed to the script, the following easybuild parameters are used:
 * `aliases` which is a list of strings that will be used to create alises to the container.
All the strings defined here can be used as commands that will run the installed tool when the module
is loaded.
 * `apptainer_params` which represents extra arguments passed to the apptainer run command when using 
the installed tool.

An example for an **.eb** file used by this easyblock:

```
easyblock = 'Apptainer'

name = 'QIIME2'
version = '2023.7'

homepage = 'http://qiime2.org/'
description = """QIIME is an open-source bioinformatics pipeline for performing microbiome analysis
 from raw DNA sequencing data."""

toolchain = SYSTEM

# parameters that will be passed to the build_container_image.sh script

# required: source ~ link to the online docker image for the tool
installopts  = '-s quay.io/qiime2/core:%(version)s '

# required: source type ~ image, since the tool is available online as a docker image
installopts += '-i image '


# how the program will be called from the command line
aliases = ["qiime"]

# parameters that will be passed to apptainer when running the container through the alias
apptainer_params = '-c'

# files and directories which are checked after the container has been built
sanity_check_paths = {
    'files': ["opt/conda/envs/%(namelower)s-%(version)s/bin/qiime"],
    'dirs': ["opt/conda/envs/%(namelower)s-%(version)s"],
}

moduleclass = 'bio'
```
