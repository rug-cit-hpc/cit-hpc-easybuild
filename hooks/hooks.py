def pre_configure_hook(self, *args, **kwargs):
    """pre-configure hook to add SLURM and pmix support."""
    if self.name == 'OpenMPI':
        self.log.info("[pre-configure hook] Adding SLURM and pmix support")
        #self.cfg['preconfigopts'] = 'sed -i "s/pmix_ext_install_dir\/lib/pmix_ext_install_dir\/lib64/g" ./configure && '
        #self.cfg['configopts'] = self.cfg['configopts'] + '--disable-dlopen --with-slurm --with-pmi=/usr --with-pmi-libdir=/usr --with-pmix=/usr --with-libevent=/usr'
        self.cfg['configopts'] = self.cfg['configopts'] + '--with-slurm --with-pmi=/usr --with-pmi-libdir=/usr/lib64 --with-pmix=/usr --with-libevent=/usr --without-verbs'
