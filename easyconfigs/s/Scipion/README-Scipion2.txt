A quick explanation where the files are from and how to repeat installation in the same way
should the circumstances still be the way they are. Currently Scipion 2.0.0 is only available
through an un-accepted pull request in the easybuilders/easybuild-easyconfigs github repo
this means that to get to some of the files is a little bit tricky. In addition to this the
easyconfigs rely on an easyblock in easybuilders/easybuild-easyblocks which is in a similar
situation. It is contained in a pull request that has not been accepted yet and is still
pending.

Quick note on how to check out a pull request

'git fetch origin pull/<PullRequest-ID>/head:<new_unique_branch_name>'

then simply check out the newly created branch

'git checkout <new_unique_branch_name>'

The reason the files have been copied over is the following:
The file 'hpc2n_slurm_hosts.template' is not made specifically for our cluster, so it needs
to be replaced both in content and in reference (in the easyconfigs) to a template file that
is made for our cluster specifically. Contrary to this, the easyblock does not have the same
limitations so it will not be copied over to our repository. You should keep this in mind if
this software needs to be re-installed.


