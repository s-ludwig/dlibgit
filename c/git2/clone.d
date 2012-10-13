module git2.clone;

import git2.checkout;
import git2.indexer;
import git2.types;

extern(C):

int git_clone(git_repository** _out, const(char)* origin_url, const(char)* workdir_path, git_indexer_stats* fetch_stats, git_indexer_stats* checkout_stats, git_checkout_opts* checkout_opts);
int git_clone_bare(git_repository** _out, const(char)* origin_url, const(char)* dest_path, git_indexer_stats* fetch_stats);
