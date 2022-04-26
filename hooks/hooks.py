CUDA_LUA_FOOTER = """local f = io.open("%(installdir)s/../../../%(name)s-%(version_major_minor)s.compat", "r")
if f ~= nil then
    -- local cuda_compat = f:read()
    local cuda_compat = "CUDA-compat/%(version_major_minor)s"
    if not ( isloaded(cuda_compat) ) then
        load(cuda_compat)
    end
    io.close(f)
end"""

def pre_configure_hook(self, *args, **kwargs):

    # OpenMPI: add SLURM and pmix support
    if self.name == 'OpenMPI':
        self.log.info("[pre-configure hook] Adding SLURM and pmix support")
        #self.cfg['preconfigopts'] = 'sed -i "s/pmix_ext_install_dir\/lib/pmix_ext_install_dir\/lib64/g" ./configure && '
        #self.cfg['configopts'] = self.cfg['configopts'] + '--disable-dlopen --with-slurm --with-pmi=/usr --with-pmi-libdir=/usr --with-pmix=/usr --with-libevent=/usr'
        #self.cfg['configopts'] = self.cfg['configopts'] + '--with-slurm --with-pmi=/usr --with-pmi-libdir=/usr/lib64 --with-pmix=/usr --with-libevent=/usr --without-verbs'
        self.cfg['configopts'] = self.cfg['configopts'] + '--with-slurm'

    # Wien2k: use srun instead of mpirun
    if self.name == 'WIEN2k':
        self.log.info("[pre-configure hook] Making sure that srun is used instead of mpirun")
        self.cfg['wien_mpirun'] = 'srun -n_NP_ _EXEC_'


def pre_module_hook(self, *args, **kwargs):

    # impi: use PMIx library
    if self.name == 'impi':
        self.log.info("[pre-module hook] Set I_MPI_PMI_LIBRARY to PMIx library")
        pmi_mod_vars = {'I_MPI_PMI_LIBRARY': '/usr/lib64/libpmix.so'}
        self.cfg.update('modextravars', pmi_mod_vars)

    # AlphaFold: set data directory
    if self.name == 'AlphaFold':
        data_dir = '/data/public/alphafold/data-2.1.0'
        extramodvars = {'ALPHAFOLD_DATA_DIR': data_dir}
        self.log.info('[pre-module hook] Setting ALPHAFOLD_DATA_DIR to ' + data_dir)
        self.cfg.update('modextravars', extramodvars)

    # Anaconda3: Execute intialization script
    if self.name == 'Anaconda3':
        luafooter =  'execute{cmd="source \'"..pathJoin(root, "/etc/profile.d/conda."..myShellType()).."\'", modeA={"load"}}'
        self.cfg.update('modluafooter', luafooter)

    # CUDA: add mechanism for optionally including a dependency on CUDA-compat module
    if self.name == 'CUDA':
        self.cfg.update('modluafooter', CUDA_LUA_FOOTER)
