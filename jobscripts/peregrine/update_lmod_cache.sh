#!/bin/bash
lmodversion=$( module --dumpversion )
/usr/share/lmod/$lmodversion/libexec/update_lmod_system_cache_files $MODULEPATH
