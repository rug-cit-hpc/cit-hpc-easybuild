setenv MODPATH /software/modules
setenv CLASSES "bio cae chem compiler data debugger devel gis lang lib math mpi numlib perf phys system toolchain tools vis" 
foreach class ($CLASSES)
   setenv MODULEPATH           `/usr/share/lmod/lmod/libexec/addto --append MODULEPATH $MODPATH/$class` 
end
setenv LMOD_RC /software/lmod/lmodrc.lua
setenv LMOD_ADMIN_FILE /software/lmod/lmodadmin.txt
setenv LMOD_PACKAGE_PATH /software/lmod/site

