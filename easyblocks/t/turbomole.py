"""
EasyBuild support for building and installing ADF, implemented as an easyblock
@author: Bob Dröge (University of Groningen)
"""
import os

from easybuild.easyblocks.generic.bundle import Bundle
from easybuild.framework.easyconfig import CUSTOM
from easybuild.tools.build_log import EasyBuildError
from easybuild.tools.modules import get_software_root

class EB_TURBOMOLE(Bundle):
    """Support for building/installing TURBOMOLE."""

    @staticmethod
    def extra_options():
        extra_vars = {
            'arch': [
                None,
                "Architecture to be used (em64t-unknown-linux-gnu%s)" % ', '.join([a for a in ['', '_smp', '_mpi']]),
                CUSTOM
            ],
        }
        return Bundle.extra_options(extra_vars)

    def __init__(self, *args, **kwargs):
        """Specify to build in install dir."""
        super(EB_TURBOMOLE, self).__init__(*args, **kwargs)
        # We are reusing the main TURBOMOLE installation, so absolute paths are needed.
        self.cfg['allow_prepend_abs_path'] = True
        if not self.cfg['arch']:
            raise EasyBuildError("Easyconfig parameter 'arch' has to be set!")

    def make_module_extra(self):
        """Add directory for specified architecture (subdirectory of the main TURBOMOLE installation) to $PATH."""
        turbomole_root = get_software_root('TURBOMOLE')
        if not turbomole_root:
            raise EasyBuildError("TURBOMOLE has to be listed as dependency!")
        self.cfg['modextrapaths'] = {
            'PATH': os.path.join(turbomole_root, 'bin', self.cfg['arch'])
        }
        return super(EB_TURBOMOLE, self).make_module_extra()

    def sanity_check_step(self):
        """Custom sanity check for TURBOMOLE."""
        
        arch = self.cfg['arch']

        custom_paths = {
            'files': ['bin/%s/dscf' % arch, 'bin/%s/ridft' % arch, 'bin/%s/aoforce' % arch,
                      'bin/%s/grad' % arch, 'bin/%s/uff' % arch],
            'dirs': []
        }

        super(EB_TURBOMOLE, self).sanity_check_step(custom_paths=custom_paths)

