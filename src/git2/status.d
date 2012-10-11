module git2.status;

import git2.common;
import git2.types;

extern(C):

enum git_status_show_t
{
    GIT_STATUS_SHOW_INDEX_AND_WORKDIR = 0,
    GIT_STATUS_SHOW_INDEX_ONLY = 1,
    GIT_STATUS_SHOW_WORKDIR_ONLY = 2,
    GIT_STATUS_SHOW_INDEX_THEN_WORKDIR = 3
}

enum 
{
    GIT_STATUS_OPT_INCLUDE_UNTRACKED = 1,
    GIT_STATUS_OPT_INCLUDE_IGNORED = 2,
    GIT_STATUS_OPT_INCLUDE_UNMODIFIED = 4,
    GIT_STATUS_OPT_EXCLUDE_SUBMODULES = 8,
    GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS = 16,
    GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH = 32
}

enum 
{
    GIT_STATUS_CURRENT = 0,
    GIT_STATUS_INDEX_NEW = 1,
    GIT_STATUS_INDEX_MODIFIED = 2,
    GIT_STATUS_INDEX_DELETED = 4,
    GIT_STATUS_WT_NEW = 8,
    GIT_STATUS_WT_MODIFIED = 16,
    GIT_STATUS_WT_DELETED = 32,
    GIT_STATUS_IGNORED = 64
}

struct git_status_options 
{
    git_status_show_t show;
    uint flags;
    git_strarray pathspec;
}

int git_status_file(uint* status_flags, git_repository* repo, const(char)* path);
int git_status_foreach(git_repository* repo, int function(const(char)*, uint, void*) callback, void* payload);
int git_status_foreach_ext(git_repository* repo, const(git_status_options)* opts, int function(const(char)*, uint, void*) callback, void* payload);
int git_status_should_ignore(int* ignored, git_repository* repo, const(char)* path);
