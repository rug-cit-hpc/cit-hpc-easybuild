#!/bin/bash

supported_archs="haswell skylake sandybridge"

usage() {
   echo "./install_easyconfigs.sh [-h] [-a architectures] -e easyconfig [-o easybuild_options]"
   echo "   -h : show this help page"
   echo "   -a : Optional. Comma separated list of architectures to submit build jobs for"
   echo "        currently supported: $supported_archs"
   echo "        if none are given jobs are submitted for all of the supported ones"
   echo "   -e : Required. Easyconfig to submit build jobs for"
   echo "   -o : Optional. Options to pass to easybuild."
   echo "   -t : Optional. Time limit for the build jobs (default: 12:00:00)."
   exit $1
}

architectures=$supported_archs
walltime=12:00:00

while getopts "ha:e:o:t:" arg; do
  case $arg in
    h)
      usage
      ;;
    a)
      architectures=$(echo $OPTARG | tr ',' ' ')
      echo $architectures
      ;;
    e)
      easyconfig=$OPTARG
      echo $easyconfig
      ;;
    o)
      eb_options=$OPTARG
      echo $eb_options
      ;;
    t)
      walltime=$OPTARG
      echo $walltime
      ;;
    *)
      usage 1
      ;;
  esac
done

if [ -z $easyconfig ]; then
   usage 1
fi

# Create and use a date based directory for storing the temporary files
date=$( date +"%Y-%m-%d" )
mkdir -p $date
cd $date

softwarename=$( basename $easyconfig .eb )
jobscriptbase=$softwarename

for arch in $architectures; do
  if [[ $supported_archs =~ $arch ]]; then
     jobscript=$softwarename.$arch.sh
     echo Creating jobscript for $arch
     # Write header for jobscript
cat << EOF > $jobscript
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --tasks-per-node=4
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
EOF
     echo "#SBATCH --time=$walltime" >> $jobscript
     if [ $arch = "haswell" ]; then
        echo "#SBATCH --partition=regular" >> $jobscript
     elif [ $arch = "skylake" ]; then
        echo "#SBATCH --partition=gpu" >> $jobscript
        echo "#SBATCH --gres=gpu:v100:1" >> $jobscript
     elif [ $arch = "sandybridge" ]; then
        echo "#SBATCH --partition=himem" >> $jobscript
     fi
     echo "#SBATCH --output=$softwarename-$arch-%A.out" >> $jobscript
     echo >> $jobscript
     echo "echo Installing $easyconfig on $arch" >> $jobscript
     echo >> $jobscript
     echo "# Install package" >> $jobscript
     echo "../eb_install.sh $easyconfig $eb_options" >> $jobscript
     # Write footer for jobscript
cat << EOF >> $jobscript
ec=\$?
if [ \$ec -ne 0 ] 
then
  # Copy the EasyBuild log from the temporary build directory to the job's directory
  eb_log_src=\$(../eb_install.sh --last-log)
  eb_log_dst="./${softwarename}-${arch}-\${SLURM_JOB_ID}-eb.log"
  echo "Software installation failed, copying EasyBuild log to \$eb_log_dst"
  cp "\$eb_log_src" "\$eb_log_dst"
fi

# Update module cache
../update_lmod_cache.sh

# Set the exit code of the job to the exit code of EasyBuild 
exit \$ec
EOF
  # Submit jobscript to Slurm
  sbatch $jobscript
  else
     echo $arch unsupported!
     exit -1
  fi
done
