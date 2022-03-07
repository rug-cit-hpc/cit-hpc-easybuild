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

