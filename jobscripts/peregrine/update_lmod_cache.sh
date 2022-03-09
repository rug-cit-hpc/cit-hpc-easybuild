#!/bin/bash
echo "Updating module cache"
lmodversion=$( module --dumpversion 2>&1 )
/usr/share/lmod/$lmodversion/libexec/update_lmod_system_cache_files $MODULEPATH
