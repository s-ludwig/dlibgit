module git2.checkout;

import git2.common;
import git2.indexer;
import git2.oid;
import git2.types;

extern(C):

enum 
{
    GIT_CHECKOUT_DEFAULT = 1,
    GIT_CHECKOUT_OVERWRITE_MODIFIED = 2,
    GIT_CHECKOUT_CREATE_MISSING = 4,
    GIT_CHECKOUT_REMOVE_UNTRACKED = 8
}

struct git_checkout_opts 
{
    uint checkout_strategy;
    int disable_filters;
    int dir_mode;
    int file_mode;
    int file_open_flags;
    int function(const(char)*, const(git_oid)*, int, void*) skipped_notify_cb;
    void* notify_payload;
    git_strarray paths;
}

int git_checkout_head(git_repository* repo, git_checkout_opts* opts, git_indexer_stats* stats);
int git_checkout_index(git_repository* repo, git_checkout_opts* opts, git_indexer_stats* stats);
int git_checkout_tree(git_repository* repo, git_object* treeish, git_checkout_opts* opts, git_indexer_stats* stats);
