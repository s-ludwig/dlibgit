module git2.checkout;

import git2.common;
import git2.diff;
import git2.indexer;
import git2.oid;
import git2.types;

extern(C):

enum git_checkout_strategy {
    NONE = 0,
    SAFE = (1u << 0),
    SAFE_CREATE = (1u << 1),
    FORCE = (1u << 2),
    ALLOW_CONFLICTS = (1u << 4),
    REMOVE_UNTRACKED = (1u << 5),
    REMOVE_IGNORED = (1u << 6),
    UPDATE_ONLY = (1u << 7),
    DONT_UPDATE_INDEX = (1u << 8),
    NO_REFRESH = (1u << 9),
    DISABLE_PATHSPEC_MATCH = (1u << 13),
    SKIP_UNMERGED = (1u << 10),
    USE_OURS = (1u << 11),
    USE_THEIRS = (1u << 12),
    UPDATE_SUBMODULES = (1u << 16),
    UPDATE_SUBMODULES_IF_CHANGED = (1u << 17),
}

enum git_checkout_notify {
    NONE      = 0,
    CONFLICT  = (1u << 0),
    DIRTY     = (1u << 1),
    UPDATED   = (1u << 2),
    UNTRACKED = (1u << 3),
    IGNORED   = (1u << 4),
}

alias git_checkout_notify_cb = int function(git_checkout_notify why, const(char)* path, const(git_diff_file)* baseline, const(git_diff_file)* target, const(git_diff_file)* workdir, void* payload);
alias git_checkout_progress_cb = void function(const(char)* path, size_t completed_steps, size_t total_steps, void* payload);

struct git_checkout_opts 
{
    uint version_ = GIT_CHECKOUT_OPTS_VERSION;
    git_checkout_strategy checkout_strategy = git_checkout_strategy.SAFE;
    int disable_filters;
    uint dir_mode;
    uint file_mode;
    int file_open_flags;
    git_checkout_notify notify_flags;
    git_checkout_notify_cb skipped_notify_cb;
    void* notify_payload;
    git_checkout_progress_cb progress_cb;
    void *progress_payload;
    git_strarray paths;
    git_tree *baseline;
}

enum GIT_CHECKOUT_OPTS_VERSION = 1;

int git_checkout_head(git_repository* repo, git_checkout_opts* opts);
int git_checkout_index(git_repository* repo, git_index *index, git_checkout_opts* opts);
int git_checkout_tree(git_repository* repo, const(git_object)* treeish, git_checkout_opts* opts);
