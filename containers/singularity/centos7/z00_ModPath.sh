MODPATH=/software/modules
CLASSES="bio cae chem compiler data debugger devel gis lang lib math mpi numlib perf phys system toolchain tools vis" 
for class in $CLASSES; do
   export MODULEPATH=$(/usr/share/lmod/lmod/libexec/addto --append MODULEPATH $MODPATH/$class)
done
export LMOD_RC=/software/lmod/lmodrc.lua
export LMOD_ADMIN_FILE=/software/lmod/lmodadmin.txt
export LMOD_PACKAGE_PATH=/software/lmod/site
