#!/bin/bash
#SBATCH --nodes=1
#SBATCH --tasks-per-node=4
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --partition=regular

# Install package
./eb_install.sh $@

# Update module cache
./update_lmod_cache.sh
