import os

from easybuild.tools.build_log import EasyBuildError


NOT_IN_GROUP_MSG = "This software can only be used by members of a particular group, "
NOT_IN_GROUP_MSG += "and you are not in this group. Please contact hpc@rug.nl if you want to be added."

GROUP_CHECK = '''
local user = capture("/usr/bin/whoami")
local groups = capture("/usr/bin/id -Gn " .. user)
if not groups:find("%s") then
    LmodError("%s")
end
'''

GROUP_SOFTWARE = {
    'Amber': ('hb%-roelfes', NOT_IN_GROUP_MSG),
    'AMS': ('hb%-gaussian', NOT_IN_GROUP_MSG),
    'Molpro': ('hb%-aim', NOT_IN_GROUP_MSG),
    'ORCA': ('hb%-orca', NOT_IN_GROUP_MSG),
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


#def parse_hook(self):
    # Check if the software should only be available to a specific group
    # Disabled for now, does not work in a container :-(
    #if self.name in GROUP_SOFTWARE:
    #    self.log.info("[pre-configure hook] Making sure that this software is only available to a specific group")
    #    self['group'] = GROUP_SOFTWARE[self.name]

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
        self.cfg.update('modluafooter', GROUP_CHECK % GROUP_SOFTWARE[self.name])

    # AlphaFold: set data directory, disable unified memory (doesn't work with V100)
    if self.name == 'AlphaFold':
        data_dir = '/data/public/alphafold/data-' + self.version
        extramodvars = {'ALPHAFOLD_DATA_DIR': data_dir, 'TF_FORCE_UNIFIED_MEMORY': '0'}
        self.log.info('[pre-module hook] Setting ALPHAFOLD_DATA_DIR to ' + data_dir)
        self.log.info('[pre-module hook] Setting TF_FORCE_UNIFIED_MEMORY to 0')
        self.cfg.update('modextravars', extramodvars)

    # Anaconda3: Execute intialization script
    if self.name == 'Anaconda3':
        luafooter =  'execute{cmd="source \'"..pathJoin(root, "/etc/profile.d/conda."..myShellType()).."\'", modeA={"load"}}'
        self.cfg.update('modluafooter', luafooter)

    # OpenMPI: add Lua code that disables UCX and libfabric on nodes with an Omnipath device
    if self.name == 'OpenMPI':
        self.cfg.update('modluafooter', OPENMPI_OPA_FOOTER)
