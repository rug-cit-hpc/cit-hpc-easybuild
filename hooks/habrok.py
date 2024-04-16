import os

from easybuild.tools.build_log import EasyBuildError
from easybuild.tools.config import ConfigurationVariables
from easybuild.tools.filetools import apply_regex_substitutions


NOT_IN_GROUP_MSG = "This software can only be used by members of the {group} group, "
NOT_IN_GROUP_MSG += "and you are not in this group. Please contact {group_owner} if you want to be added."

GROUP_CHECK = '''
local user = capture("/usr/bin/whoami")
local groups = capture("/usr/bin/id -Gn " .. user)
if not groups:find("{group_lua}") then
    LmodError("{not_in_group_msg}")
end
'''

GROUP_SOFTWARE = {
    'Amber': ('hb-roelfes', 'hpc@rug.nl', NOT_IN_GROUP_MSG),
    'AMS': ('hb-gaussian', 'dr. J.E.M.N. Klein', NOT_IN_GROUP_MSG),
    'CASTEP': ('hb-castep', '', "This software is only available to a specific group of users."),
    'CPLEX': ('hb-cplex', 'hpc@rug.nl', NOT_IN_GROUP_MSG),
    'FLUENT': ('hb-solar_racing', 'the solar racing group admin', NOT_IN_GROUP_MSG),
    'Gaussian': ('hb-gaussian', 'dr. J.E.M.N. Klein', NOT_IN_GROUP_MSG),
    'GaussView': ('hb-gaussian', 'dr. J.E.M.N. Klein', NOT_IN_GROUP_MSG),
    'Molpro': ('hb-aim', 'hpc@rug.nl', NOT_IN_GROUP_MSG),
    'Mplus': ('hb-mplus', 'hpc@rug.nl', NOT_IN_GROUP_MSG),
    'ORCA': ('hb-orca', 'hpc@rug.nl', NOT_IN_GROUP_MSG),
    'VASP': ('hb-vasp', 'r.w.a.havenith@rug.nl / jagoda.slawinska@rug.nl / f.maresca@rug.nl', NOT_IN_GROUP_MSG),
}

LICENSES = {
    'MATLAB': {
      'license_server': 'lic004.workspace.rug.nl',
      'license_server_port': '27000',
    },
    'Mathematica': {
        'license_server': 'lic005.workspace.rug.nl',
    },
    'COMSOL': {
        'license_file': 'license.dat',
    }
}

OPENMPI_OPA_FOOTER = '''
function has_opa()
  local f = io.open("/dev/hfi1_0", "r")
  if f ~= nil then io.close(f) return true else return false end
end

if has_opa()
then
  setenv("OMPI_MCA_btl", "^openib,ofi")
  setenv("OMPI_MCA_pml", "^ucx")
end
'''

KRAKEN2_LOAD_MSG = '''The standard Kraken2 database from https://benlangmead.github.io/aws-indexes/k2
can be found in /scratch/public/genomes/kraken2db. You can use this database by executing:
export KRAKEN2_DEFAULT_DB=/scratch/public/genomes/kraken2db
'''

AMS_MOD_LUA_FOOTER =  """
if os.getenv("TMPDIR") then
    setenv("SCM_TMPDIR", os.getenv("TMPDIR"))
else
    local user = capture("/usr/bin/whoami")
    setenv("SCM_TMPDIR", pathJoin("/scratch", user))
end
"""


def parse_hook(self):
    # Check if the software should only be available to a specific group
    # Disabled for now, does not work in a container :-(
    #if self.name in GROUP_SOFTWARE:
    #    self.log.info("[pre-configure hook] Making sure that this software is only available to a specific group")
    #    self['group'] = GROUP_SOFTWARE[self.name]

    # Skip sanity check for git-lfs, which doesn not work with RPATH enabled
    # because it's built with Go:
    # https://github.com/easybuilders/easybuild-easyconfigs/issues/17516
    if self.name == 'git-lfs':
        self['skipsteps'] = ['sanitycheck'] if not 'skipsteps' in self else self['skipsteps'] + ['sanitycheck']

    # Disable OpenMM GPU tests if we are building on a host without a GPU
    if self.name == 'OpenMM' and not os.environ.get('SW_BUILD_HOST_HAS_GPU', None):
        self.log.error(self['runtest'])
        self['runtest'] = self['runtest'][0:self['runtest'].rindex("'")] + '|(Cuda)|(OpenCL)\'" '

    # json-c: fix failing tests due to not finding a shared library
    if self.name == 'json-c':
        self['pretestopts'] = 'ln -s ../libjson-c.so.5 tests/libjson-c.so.5 && USE_VALGRIND=0 '

    # Xerces-C++: fix failing tests due to not finding a shared library
    if self.name == 'Xerces-C++':
        self['pretestopts'] = 'export LD_LIBRARY_PATH=%(builddir)s/easybuild_obj/src:$LD_LIBRARY_PATH && ' + (self['pretestopts'] if 'pretestopts' in self else '')

    # Apptainer: set the correct installation directory
    if self['easyblock'] == "Apptainer":
        self.log.info("[parse hook] Checking and setting the container installation path")
        if 'EB_HABROK_CONTAINER_PATH' not in os.environ:
            raise EasyBuildError('Apptainer builds require $EB_HABROK_CONTAINER_PATH to be set!')
        ConfigurationVariables()._FrozenDict__dict['installpath'] = os.getenv('EB_HABROK_CONTAINER_PATH')


def post_extensions_hook(self, *args, **kwargs):
    # Replace the -march=native flags in the Makeconf file of R installations by -march=x86-64-v3.
    # This ensures that user-installed extensions are compatible with all nodes.
    if self.name == 'R':
        self.log.info("[post-extensions hook] Replace -march=native by -march=x86-64-v3 in etc/Makeconf")
        apply_regex_substitutions(os.path.join(self.installdir, 'lib64', 'R', 'etc', 'Makeconf'), [
            (r'(.*FLAGS = .*)(-march=native)(.*)', r'\1-march=x86-64-v3\3'),
        ])


def pre_configure_hook(self, *args, **kwargs):
    # Check if a license file/server needs to be configured
    if self.name in LICENSES:
        for lic_key, lic_value in LICENSES[self.name].items():
            self.log.info("[pre-configure hook] Setting %s to %s" % (lic_key, lic_value))
            self.cfg[lic_key] = lic_value

    # MATLAB requires a file installation key
    if self.name == 'MATLAB' and not 'EB_MATLAB_KEY' in os.environ:
        raise EasyBuildError('MATLAB requires $EB_MATLAB_KEY to be set!')

    # Wien2k: use srun instead of mpirun
    if self.name == 'WIEN2k':
        self.log.info("[pre-configure hook] Making sure that srun is used instead of mpirun")
        self.cfg['wien_mpirun'] = 'srun -n_NP_ _EXEC_'

    # PyTorch: disable two additional tests that fail due to a timeout
    if self.name == 'PyTorch':
        self.log.info("[pre-configure hook] Disabling two additional tests...")
        self.cfg.update('excluded_tests',
            {'': self.cfg['excluded_tests'][''] + ['distributed/rpc/test_faulty_agent', 'distributed/rpc/test_tensorpipe_agent']}
        )
        self.log.info("[pre-configure hook] Updated list of excluded tests: " + ', '.join(self.cfg['excluded_tests']['']))


def pre_module_hook(self, *args, **kwargs):
    # Add a load message for software that is only available to a certain group
    if self.name in GROUP_SOFTWARE:
        group, owner, msg = GROUP_SOFTWARE[self.name]
        self.cfg.update('modluafooter',
            GROUP_CHECK.format(group_lua=group.replace('-', '%-'), not_in_group_msg=msg.format(group=group, group_owner=owner))
        )

    # AlphaFold: set data directory, disable unified memory (doesn't work with V100)
    if self.name == 'AlphaFold':
        data_dir = '/scratch/public/%s/%s' % (self.name, self.version)
        extramodvars = {'ALPHAFOLD_DATA_DIR': data_dir}
        self.log.info('[pre-module hook] Setting ALPHAFOLD_DATA_DIR to ' + data_dir)
        #self.log.info('[pre-module hook] Setting TF_FORCE_UNIFIED_MEMORY to 0')
        if os.getenv('SW_STACK_ARCH', '') == 'x86_64/intel/skylake_avx512':
            # Building for V100 without CUDA unified memory support
            extramodvars['TF_FORCE_UNIFIED_MEMORY'] = '0'
            self.log.info('[pre-module hook] Setting TF_FORCE_UNIFIED_MEMORY to 0')
        self.cfg.update('modextravars', extramodvars)

    # ColabFold: set data directory
    if self.name == 'ColabFold':
        data_dir = '/scratch/public/%s/%s' % (self.name, self.version)
        extramodvars = {'COLABFOLD_DATA_DIR': data_dir} #, 'TF_FORCE_UNIFIED_MEMORY': '0'}
        self.log.info('[pre-module hook] Setting COLABFOLD_DATA_DIR to ' + data_dir)
        if os.getenv('SW_STACK_ARCH', '') == 'x86_64/intel/skylake_avx512':
            # Building for V100 without CUDA unified memory support
            extramodvars['TF_FORCE_UNIFIED_MEMORY'] = '0'
            self.log.info('[pre-module hook] Setting TF_FORCE_UNIFIED_MEMORY to 0')
        self.cfg.update('modextravars', extramodvars)

    # AMS: set MPI launcher, set license file, disable load msg, and inject module footer for $SCM_TMPDIR
    if self.name == 'AMS':
        self.log.info('[pre-module hook] Setting SCM_MPIRUN_EXE=mpirun')
        self.cfg.update('modextravars', {'SCM_MPIRUN_EXE': 'mpirun'})
        self.log.info('[pre-module hook] Setting path to license file')
        self.cfg.update('modextravars', {'SCMLICENSE': '%(installdir)s/license.txt'})
        self.log.info('[pre-module hook] Disable default module load message')
        self.cfg['modloadmsg'] = ''
        self.log.info('[pre-module hook] Injecting module footer for setting $SCM_TMPDIR')
        self.cfg.update('modluafooter', AMS_MOD_LUA_FOOTER)

    # Anaconda3: Execute intialization script
    if self.name == 'Anaconda3':
        luafooter =  'execute{cmd="source \'"..pathJoin(root, "/etc/profile.d/conda."..myShellType()).."\'", modeA={"load"}}'
        self.cfg.update('modluafooter', luafooter)

    # Kraken2: add module load message about datasets
    if self.name == 'Kraken2':
        self.cfg['modloadmsg'] = KRAKEN2_LOAD_MSG

    # OpenMPI: add Lua code that disables UCX and libfabric on nodes with an Omnipath device
    if self.name == 'OpenMPI':
        self.cfg.update('modluafooter', OPENMPI_OPA_FOOTER)
