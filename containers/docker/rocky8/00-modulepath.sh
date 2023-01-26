[ -z "$MODULEPATH" ] &&
  [ "$(readlink /etc/alternatives/modules.sh)" = "/usr/share/lmod/lmod/init/profile" -o -f /etc/profile.d/z00_lmod.sh ] &&
  export MODULEPATH=/cvmfs/hpc.rug.nl/versions/modules
#  export MODULEPATH=/etc/modulefiles:/usr/share/modulefiles || :
