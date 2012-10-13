module git2.repository;

import git2.oid;
import git2.types;

extern(C):

enum 
{
    GIT_REPOSITORY_OPEN_NO_SEARCH = 1,
    GIT_REPOSITORY_OPEN_CROSS_FS = 2
}

enum 
{
    GIT_REPOSITORY_INIT_BARE = 1,
    GIT_REPOSITORY_INIT_NO_REINIT = 2,
    GIT_REPOSITORY_INIT_NO_DOTGIT_DIR = 4,
    GIT_REPOSITORY_INIT_MKDIR = 8,
    GIT_REPOSITORY_INIT_MKPATH = 16,
    GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE = 32
}

enum 
{
    GIT_REPOSITORY_INIT_SHARED_UMASK = 0,
    GIT_REPOSITORY_INIT_SHARED_GROUP = 1533,
    GIT_REPOSITORY_INIT_SHARED_ALL = 1535
}

struct git_repository_init_options 
{
    uint32_t flags;
    uint32_t mode;
    const(char)* workdir_path;
    const(char)* description;
    const(char)* template_path;
    const(char)* initial_head;
    const(char)* origin_url;
}

int git_repository_config(git_config** _out, git_repository* repo);
int git_repository_detach_head(git_repository* repo);
int git_repository_discover(char* repository_path, size_t size, const(char)* start_path, int across_fs, const(char)* ceiling_dirs);
void git_repository_free(git_repository* repo);
int git_repository_hashfile(git_oid* _out, git_repository* repo, const(char)* path, git_otype type, const(char)* as_path);
int git_repository_head(git_reference** head_out, git_repository* repo);
int git_repository_head_detached(git_repository* repo);
int git_repository_head_orphan(git_repository* repo);
int git_repository_index(git_index** _out, git_repository* repo);
int git_repository_init(git_repository** repo_out, const(char)* path, uint is_bare);
int git_repository_init_ext(git_repository** repo_out, const(char)* repo_path, git_repository_init_options* opts);
int git_repository_is_bare(git_repository* repo);
int git_repository_is_empty(git_repository* repo);
int git_repository_message(char* buffer, size_t len, git_repository* repo);
int git_repository_message_remove(git_repository* repo);
int git_repository_odb(git_odb** _out, git_repository* repo);
int git_repository_open(git_repository** repository, const(char)* path);
int git_repository_open_ext(git_repository** repo, const(char)* start_path, uint32_t flags, const(char)* ceiling_dirs);
const(char)* git_repository_path(git_repository* repo);
void git_repository_set_config(git_repository* repo, git_config* config);
int git_repository_set_head(git_repository* repo, const(char)* refname);
int git_repository_set_head_detached(git_repository* repo, const(git_oid)* commitish);
void git_repository_set_index(git_repository* repo, git_index* index);
void git_repository_set_odb(git_repository* repo, git_odb* odb);
int git_repository_set_workdir(git_repository* repo, const(char)* workdir, int update_gitlink);
const(char)* git_repository_workdir(git_repository* repo);
int git_repository_wrap_odb(git_repository** repository, git_odb* odb);
