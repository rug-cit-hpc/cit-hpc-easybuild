#!/bin/bash
archs="amd/zen amd/zen3 intel/icelake intel/skylake_avx512"
for arch in $archs; do
  outfile=$( echo $arch | tr '/' '_').out
  ls -d /cvmfs/hpc.rug.nl/versions/2023.01/rocky8/x86_64/$arch/software/*/* | sort | awk -F '/' '{print $11 "-" $12}'  > $outfile
done
