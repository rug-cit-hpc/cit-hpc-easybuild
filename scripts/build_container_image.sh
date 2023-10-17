#!/bin/bash

# Author: Aurel Istrate (c.a.istrate@rug.nl)
# Based on a similar script from the ComputeCanada team ~ https://github.com/ComputeCanada/containers-recipes\

print_help_text() {
  SCRIPT=$(readlink -f "$0")
  printf "\nCreate a Singularity/Apptainer container. You can choose to make a sif file or a sandbox. Input source can be a def file or a Docker image.\n\n$SCRIPT [-h|-d|-b] -n <tool_name_for_output_file/directory> -v <tool_version_for_output_file/directory> -i <def|image> -s <myproject/docker-repository-name>|<myimage:mytag>|<myfile.def> -t <sandbox|sif> [-o <output/directory | -z <def_file_source/directory>] \n\n"
  echo "-n      name of the tool container to build. This will be combined with the version to make the container (either sif or directory) e.g. enter 'mynewtool' to create mynewtool-1.0.0 or mynewtool-1.0.0.sif (depending on the version and sandbox/sif mode entered). Will be created in the output directory, which defaults to the current working directory."
  echo "-v      version of the tool to be added to the output filename e.g. '1.28'. This is combined with the tool name prefix to create for example mytool-1.28.sif or mytool-1.28/"
  echo "-i      Input source type, one of <def|image>"
  echo "-s      Source to use. Can be a def file or Docker image name, according to the option -i."
  echo "         - Building from a docker image: the value should be the parameter you would typically pass to docker pull"
  echo "         - Building from def file recipe: the value should be <myfile.def>"
  echo "-t      type of container to build. Either sandbox or sif, i.e. -t <sandbox|sif>"
  echo "-o      (optional) the directory in which the image will be created, defaults to the current working directory"
  echo "-z      (optional) the source directory, where the def file is found. Only works with '-i def' and defaults to the current working directory"
  echo "-d      Dry run - commands are displayed, but not run"
  echo "-b      Debug prints extra information"
  echo "-h      show help text"
}

cleanup() {
#  if [[ $USER == "containeruser" ]]; then
#		echo "Changing owner of the container directory to containeruser:rsnt_containers with sudo /usr/bin/chown -R containeruser:rsnt_containers $TARGET_CONTAINER"
#		sudo /usr/bin/chown -R containeruser:rsnt_containers $TARGET_CONTAINER
#		echo "Adjusting permissions of $TARGET_CONTAINER with chmod -R u+w,go+rX $TARGET_CONTAINER"
#		chmod -R u+w,go+rX $TARGET_CONTAINER
#		echo "Tagging large folders for cataloging by CVMFS"
#		autocatalog.py --path $TARGET_CONTAINER --size 20000
#	fi
  echo "Cleaning up"

}

# no input parameters
if [ $# = 0 ]
then
  print_help_text
  exit 0
fi

# default values
TARGET_DIR=$PWD
SOURCE_DIR=$PWD
TARGET_CONTAINER=
APPTAINER_ARGS=()
dry_run=false
debug=false

# handle input arguments
while getopts "n:v:i:s:t:o:z:dbh" opt; do
  case $opt in
    n)  tool_name=$OPTARG;;
    v)  version=$OPTARG;;
    i)  source_type=$OPTARG;;
    s)  source_name=$OPTARG;;
    t)  container_type=$OPTARG;;
    o)  TARGET_DIR=$OPTARG;;
    z)  SOURCE_DIR=$OPTARG;;
    d)  dry_run=true;;
    b)  debug=true;;
    h)  print_help_text;
        exit 0;;
    \?) echo "ERROR: Invalid option";
        print_help_text;
        exit 0;;
  esac
done

# debug statement
if [ $debug ]
then
  echo "tool_name      = $tool_name";
  echo "version        = $version";
  echo "source_type    = $source_type";
  echo "source_name    = $source_name";
  echo "container_type = $container_type";
  echo "TARGET_DIR     = $TARGET_DIR";
  echo "SOURCE_DIR     = $SOURCE_DIR";
  echo "dry_run        = $dry_run";
  printf "\n"
fi

# check and set up arguments
# tool name
if [ -z $tool_name ];
then
  echo "ERROR: Absent tool name (-n <tool_name>) in arguments provided. This is the prefix of the file or directory being built by the script and will have the -v version number added (final result example: mytool-2.34 directory or mytool-2.34.sif). This file or directory must *not* already exist."
  exit 1;
fi
# remove .sif suffix from $tool_name, if it exists.
tool_name=${tool_name%.sif}


# version
if  [ -z $version ];
then
  echo "ERROR: Version missing. You must enter a version number for the tool. This will be added into the sif file name."
  exit 1;
else
  regex='^[0-9]+([.][0-9]+)*$'
  if ! [[ $version =~ $regex ]] ; then
    echo "ERROR: Version (-v) option is not a valid number.";
    exit 1;
  fi
fi

# build target name: toolname-version[.sif]
tool_and_version="$tool_name-$version"
if [[ "$container_type" == "sandbox" ]]; then
  TARGET_CONTAINER="$TARGET_DIR/$tool_and_version"
else
  TARGET_CONTAINER="$TARGET_DIR/$tool_and_version.sif"
fi
if [[ -e "$TARGET_CONTAINER" ]]; then
	echo "ERROR: container $TARGET_CONTAINER already exists. Please remove it before continuing."
	exit 1
fi
printf "Building $TARGET_CONTAINER\n"


# source name
if [[ -z $source_name ]]; then
	echo "ERROR: You must specify a source (option -s)"
	exit 1
fi


# source type and file
if [[ "$source_type" != "def" && "$source_type" != "image" ]]; then
	echo "ERROR: Unknown source type $source_type. Source type (option -i) must be either def or image"
	exit 1;
fi
if [[ "$source_type" == "def" ]]; then
	if [[ ${source_name::1} == "/" || ${source_name::1} == "." || ${source_name::1} == "~" ]]; then
		echo "ERROR: source file $source_name should not start with /, . or ~"
		echo "Please provide a relative path within $SOURCE_DIR"
		exit 1
	fi
	source_file=$SOURCE_DIR/$source_name
	if [[ ! -f $source_file ]]; then
		echo "ERROR: File not found $source_file"
		exit 1;
	fi
fi


# target container type
if [[ "$container_type" != "sandbox" && "$container_type" != "sif" ]]; then
	echo "ERROR: Unknown container type requested: $container_type. Valid values for option -t are <sif|sandbox>."
	exit 1;
fi
if [[ "$container_type" == "sandbox" ]]; then
	APPTAINER_ARGS+=(--sandbox)
fi


# build the container
printf "apptainer version: "
apptainer version

command_success=0
failed_msg="\nERROR: build failed\n"
success_msg="\nBuild completed successfully!\nNew Apptainer/Singularity image: $TARGET_CONTAINER\n"


# mode 1: build apptainer image from def file
# mode 2: build apptainer image from online docker image
if [[ "$source_type" == "def" || "$source_type" == "image" ]]; then
  if [[ "$source_type" == "def" ]]; then
    cmd="apptainer build ${APPTAINER_ARGS[*]} $TARGET_CONTAINER $source_file"
    echo "Building from def file (creating Apptainer image from recipe)"
  else
    cmd="apptainer build ${APPTAINER_ARGS[*]} $TARGET_CONTAINER docker://$source_name"
    echo "Building from docker image"
  fi

  if [ $dry_run = true ]; then
    printf "Command that runs when not in dry_run (-d) mode:\n  $cmd\n"
  else
    printf "** Running: $cmd\n"
    $cmd && command_success=1
  fi

  if [ $dry_run = true ]; then
    if [ $command_success = 1 ]; then
      printf $success_msg
      cleanup
    else
      printf $failed_msg
      cleanup
      exit 1;
    fi
  else
    cleanup
    exit 0; # exit from dry run
  fi
fi
