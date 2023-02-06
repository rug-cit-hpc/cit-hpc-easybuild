# x86_64 CPU architecture specifications
# Software path stack           | Vendor ID     | List of defining CPU features
#"x86_64/intel/haswell"         "GenuineIntel"  "avx2 fma"              # Intel Haswell, Broadwell
"x86_64/intel/skylake_avx512"   "GenuineIntel"  "avx2 fma avx512f avx512bw avx512cd avx512dq avx512vl"  # Intel Skylake, Cascade Lake
"x86_64/intel/icelake"          "GenuineIntel"  "avx2 fma avx512_vnni avx512_vbmi2 avx512_bitalg" # Intel Icelake
"x86_64/amd/zen"                "AuthenticAMD"  "avx2 fma"              # AMD Naples
#"x86_64/amd/zen2"              "AuthenticAMD"  "avx2 fma clwb"         # AMD Rome
"x86_64/amd/zen3"               "AuthenticAMD"  "avx2 fma vaes"         # AMD Milan, Milan-X
