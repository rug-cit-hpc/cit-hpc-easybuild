#!/bin/bash
#SBATCH --output=logs/slurm-%j.out

if [ ! $PBS_O_WORKDIR ]
    then
        PBS_O_WORKDIR="$PWD"
fi

cd $PBS_O_WORKDIR

if [ ! "$command" ]
    then
	    echo -e "Error: script must be supplied with a command"
	    exit 1
	else
    	echo "$command"
	    eval "$command"
fi
sleep 20
exit 0
