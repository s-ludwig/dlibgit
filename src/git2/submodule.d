module git2.submodule;

import git2.oid;
import git2.types;

extern(C):

auto GIT_SUBMODULE_STATUS_IS_UNMODIFIED(T)(T S)
{
    return (((S) & ~(GIT_SUBMODULE_STATUS_IN_HEAD | GIT_SUBMODULE_STATUS_IN_INDEX | GIT_SUBMODULE_STATUS_IN_CONFIG | GIT_SUBMODULE_STATUS_IN_WD)) == 0);
}

enum git_submodule_update_t
{
    GIT_SUBMODULE_UPDATE_DEFAULT = -1,
    GIT_SUBMODULE_UPDATE_CHECKOUT = 0,
    GIT_SUBMODULE_UPDATE_REBASE = 1,
    GIT_SUBMODULE_UPDATE_MERGE = 2,
    GIT_SUBMODULE_UPDATE_NONE = 3
}

enum git_submodule_status_t
{
    GIT_SUBMODULE_STATUS_IN_HEAD = 1,
    GIT_SUBMODULE_STATUS_IN_INDEX = 2,
    GIT_SUBMODULE_STATUS_IN_CONFIG = 4,
    GIT_SUBMODULE_STATUS_IN_WD = 8,
    GIT_SUBMODULE_STATUS_INDEX_ADDED = 16,
    GIT_SUBMODULE_STATUS_INDEX_DELETED = 32,
    GIT_SUBMODULE_STATUS_INDEX_MODIFIED = 64,
    GIT_SUBMODULE_STATUS_WD_UNINITIALIZED = 128,
    GIT_SUBMODULE_STATUS_WD_ADDED = 256,
    GIT_SUBMODULE_STATUS_WD_DELETED = 512,
    GIT_SUBMODULE_STATUS_WD_MODIFIED = 1024,
    GIT_SUBMODULE_STATUS_WD_INDEX_MODIFIED = 2048,
    GIT_SUBMODULE_STATUS_WD_WD_MODIFIED = 4096,
    GIT_SUBMODULE_STATUS_WD_UNTRACKED = 8192
}

enum git_submodule_ignore_t
{
    GIT_SUBMODULE_IGNORE_DEFAULT = -1,
    GIT_SUBMODULE_IGNORE_NONE = 0,
    GIT_SUBMODULE_IGNORE_UNTRACKED = 1,
    GIT_SUBMODULE_IGNORE_DIRTY = 2,
    GIT_SUBMODULE_IGNORE_ALL = 3
}

struct git_submodule { }

int git_submodule_add_finalize(git_submodule* submodule);
int git_submodule_add_setup(git_submodule** submodule, git_repository* repo, const(char)* url, const(char)* path, int use_gitlink);
int git_submodule_add_to_index(git_submodule* submodule, int write_index);
int git_submodule_fetch_recurse_submodules(git_submodule* submodule);
int git_submodule_foreach(git_repository* repo, int function(git_submodule*, const(char)*, void*) callback, void* payload);
const(git_oid)* git_submodule_head_oid(git_submodule* submodule);
git_submodule_ignore_t git_submodule_ignore(git_submodule* submodule);
const(git_oid)* git_submodule_index_oid(git_submodule* submodule);
int git_submodule_init(git_submodule* submodule, int overwrite);
int git_submodule_lookup(git_submodule** submodule, git_repository* repo, const(char)* name);
const(char)* git_submodule_name(git_submodule* submodule);
int git_submodule_open(git_repository** repo, git_submodule* submodule);
git_repository* git_submodule_owner(git_submodule* submodule);
const(char)* git_submodule_path(git_submodule* submodule);
int git_submodule_reload(git_submodule* submodule);
int git_submodule_reload_all(git_repository* repo);
int git_submodule_save(git_submodule* submodule);
int git_submodule_set_fetch_recurse_submodules(git_submodule* submodule, int fetch_recurse_submodules);
git_submodule_ignore_t git_submodule_set_ignore(git_submodule* submodule, git_submodule_ignore_t ignore);
git_submodule_update_t git_submodule_set_update(git_submodule* submodule, git_submodule_update_t update);
int git_submodule_set_url(git_submodule* submodule, const(char)* url);
int git_submodule_status(uint* status, git_submodule* submodule);
int git_submodule_sync(git_submodule* submodule);
git_submodule_update_t git_submodule_update(git_submodule* submodule);
const(char)* git_submodule_url(git_submodule* submodule);
const(git_oid)* git_submodule_wd_oid(git_submodule* submodule);
