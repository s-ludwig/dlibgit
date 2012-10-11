module git2.remote;

import git2.common;
import git2.indexer;
import git2.net;
import git2.oid;
import git2.types;

extern(C):

enum 
{
    GIT_REMOTE_DOWNLOAD_TAGS_UNSET = 0,
    GIT_REMOTE_DOWNLOAD_TAGS_NONE = 1,
    GIT_REMOTE_DOWNLOAD_TAGS_AUTO = 2,
    GIT_REMOTE_DOWNLOAD_TAGS_ALL = 3
}

enum git_remote_completion_type
{
    GIT_REMOTE_COMPLETION_DOWNLOAD = 0,
    GIT_REMOTE_COMPLETION_INDEXING = 1,
    GIT_REMOTE_COMPLETION_ERROR = 2
}

struct git_remote_callbacks 
{
    void function(const(char)*, int, void*) progress;
    int function(git_remote_completion_type, void*) completion;
    int function(const(char)*, const(git_oid)*, const(git_oid)*, void*) update_tips;
    void* data;
}

int git_remote_add(git_remote** _out, git_repository* repo, const(char)* name, const(char)* url);
int git_remote_autotag(git_remote* remote);
void git_remote_check_cert(git_remote* remote, int check);
int git_remote_connect(git_remote* remote, int direction);
int git_remote_connected(git_remote* remote);
void git_remote_disconnect(git_remote* remote);
int git_remote_download(git_remote* remote, git_off_t* bytes, git_indexer_stats* stats);
const(git_refspec)* git_remote_fetchspec(git_remote* remote);
void git_remote_free(git_remote* remote);
int git_remote_list(git_strarray* remotes_list, git_repository* repo);
int git_remote_load(git_remote** _out, git_repository* repo, const(char)* name);
int git_remote_ls(git_remote* remote, git_headlist_cb list_cb, void* payload);
const(char)* git_remote_name(git_remote* remote);
int git_remote_new(git_remote** _out, git_repository* repo, const(char)* name, const(char)* url, const(char)* fetch);
const(git_refspec)* git_remote_pushspec(git_remote* remote);
const(char)* git_remote_pushurl(git_remote* remote);
int git_remote_save(const(git_remote)* remote);
void git_remote_set_autotag(git_remote* remote, int value);
void git_remote_set_callbacks(git_remote* remote, git_remote_callbacks* callbacks);
int git_remote_set_fetchspec(git_remote* remote, const(char)* spec);
int git_remote_set_pushspec(git_remote* remote, const(char)* spec);
int git_remote_set_pushurl(git_remote* remote, const(char)* url);
int git_remote_set_url(git_remote* remote, const(char)* url);
int git_remote_supported_url(const(char)* url);
int git_remote_update_tips(git_remote* remote);
const(char)* git_remote_url(git_remote* remote);
int git_remote_valid_url(const(char)* url);
