/*
  *             Copyright David Nadlinger 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.remote;

import git.repository;
import git.types;
import git.util;

import git2.net;
import git2.remote;
import git2.types;

import std.conv : to;

///
enum GitDirection
{
    ///
    fetch = GIT_DIRECTION_FETCH,

    ///
    push = GIT_DIRECTION_PUSH
}

///
enum GitRemoteAutotagOption
{
    ///
    automatic = 0,

    ///
    none = 1,

    ///
    all = 2
}


///
struct GitRemote
{
    // Internal, see free-standing constructor functions below.
    private this(GitRepo repo, git_remote* remote)
    {
        _repo = repo;
        _data = Data(remote);
    }

    ///
    void save()
    {
        require(git_remote_save(_data._payload) == 0);
    }

    ///
    @property string name() const
    {
        return to!string(git_remote_name(_data._payload));
    }

    ///
    @property string url() const
    {
        return to!string(git_remote_url(_data._payload));
    }

    ///
    @property void name(in char[] url)
    {
        require(git_remote_set_url(_data._payload, url.gitStr) == 0);
    }

    ///
    @property string pushURL() const
    {
        return to!string(git_remote_pushurl(_data._payload));
    }

    ///
    @property void pushURL(in char[] url)
    {
        require(git_remote_set_pushurl(_data._payload, url.gitStr) == 0);
    }

    ///
    void connect(GitDirection direction)
    {
        require(git_remote_connect(_data._payload, cast(git_direction)direction) == 0);
    }

    ///
    @property bool connected()
    {
        return git_remote_connected(_data._payload) != 0;
    }

    ///
    void stop()
    {
        git_remote_stop(_data._payload);
    }

    ///
    void disconnect()
    {
        git_remote_disconnect(_data._payload);
    }

    ///
    void download(TransferCallbackDelegate progressCallback = null)
    {
        static struct Ctx { TransferCallbackDelegate dg; }
        extern(C) static int cCallback(const(git_transfer_progress)* stats, void* payload)
        {
            auto dg = (cast(Ctx*)payload).dg;
            if (dg)
            {
                GitTransferProgress tp;
                tp.tupleof = stats.tupleof;
                return dg(tp);
            }
            else
            {
                return 0;
            }
        }

        assert(connected, "Must connect(GitDirection.push) before invoking download().");

        immutable ctx = Ctx(progressCallback);
        if (progressCallback)
        {
            require(git_remote_download(_data._payload, &cCallback, cast(void*)&ctx) == 0);
        }
        else
        {
            require(git_remote_download(_data._payload, null, null) == 0);
        }
    }

private:
    struct Payload
    {
        this(git_remote* payload)
        {
            _payload = payload;
        }

        ~this()
        {
            if (_payload !is null)
            {
                git_remote_free(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        git_remote* _payload;
    }

    // Reference to the parent repository to keep it alive.
    GitRepo _repo;

    import std.typecons : RefCounted, RefCountedAutoInitialize;
    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;
}

///
GitRemote createRemote(GitRepo repo, in char[] name, in char[] url)
{
    git_remote* result;
    require(git_remote_create(&result, repo.cHandle, name.gitStr, url.gitStr) == 0);
    return GitRemote(repo, result);
}

///
GitRemote createRemoteInMemory(GitRepo repo, in char[] fetch, in char[] url)
{
    git_remote* result;
    require(git_remote_create_inmemory(&result, repo.cHandle, fetch.gitStr, url.gitStr) == 0);
    return GitRemote(repo, result);
}

///
GitRemote loadRemote(GitRepo repo, in char[] name)
{
    git_remote* result;
    require(git_remote_load(&result, repo.cHandle, name.gitStr) == 0);
    return GitRemote(repo, result);
}


/+ TODO: Port these.

extern (C):

alias git_remote_rename_problem_cb = int function(const(char)* problematic_refspec, void *payload);

int git_remote_add_fetch(git_remote *remote, const(char)* refspec);

int git_remote_get_fetch_refspecs(git_strarray *array, git_remote *remote);

int git_remote_add_push(git_remote *remote, const(char)* refspec);

int git_remote_get_push_refspecs(git_strarray *array, git_remote *remote);

void git_remote_clear_refspecs(git_remote *remote);

size_t git_remote_refspec_count(git_remote *remote);

const(git_refspec)* git_remote_get_refspec(git_remote *remote, size_t n);

int git_remote_remove_refspec(git_remote *remote, size_t n);

int git_remote_ls(git_remote *remote, git_headlist_cb list_cb, void *payload);

int git_remote_update_tips(git_remote *remote);

int git_remote_valid_url(const(char)* url);

int git_remote_supported_url(const(char)* url);

int git_remote_list(git_strarray *out_, git_repository *repo);

void git_remote_check_cert(git_remote *remote, int check);

void git_remote_set_cred_acquire_cb(
    git_remote *remote,
    git_cred_acquire_cb cred_acquire_cb,
    void *payload);

int git_remote_set_transport(
    git_remote *remote,
    git_transport *transport);

enum git_remote_completion_type {
    GIT_REMOTE_COMPLETION_DOWNLOAD,
    GIT_REMOTE_COMPLETION_INDEXING,
    GIT_REMOTE_COMPLETION_ERROR,
} ;

mixin _ExportEnumMembers!git_remote_completion_type;

struct git_remote_callbacks {
    uint version_ = GIT_REMOTE_CALLBACKS_VERSION;
    void function(const(char)* str, int len, void *data) progress;
    int function(git_remote_completion_type type, void *data) completion;
    int function(const(char)* refname, const(git_oid)* a, const(git_oid)* b, void *data) update_tips;
    void *payload;
}

enum GIT_REMOTE_CALLBACKS_VERSION = 1;
enum git_remote_callbacks GIT_REMOTE_CALLBACKS_INIT = { GIT_REMOTE_CALLBACKS_VERSION };

int git_remote_set_callbacks(git_remote *remote, git_remote_callbacks *callbacks);

const(git_transfer_progress)*  git_remote_stats(git_remote *remote);

enum git_remote_autotag_option_t {
    GIT_REMOTE_DOWNLOAD_TAGS_AUTO = 0,
    GIT_REMOTE_DOWNLOAD_TAGS_NONE = 1,
    GIT_REMOTE_DOWNLOAD_TAGS_ALL = 2
} ;

mixin _ExportEnumMembers!git_remote_autotag_option_t;

git_remote_autotag_option_t git_remote_autotag(git_remote *remote);

void git_remote_set_autotag(
    git_remote *remote,
    git_remote_autotag_option_t value);

int git_remote_rename(
    git_remote *remote,
    const(char)* new_name,
    git_remote_rename_problem_cb callback,
    void *payload);

int git_remote_update_fetchhead(git_remote *remote);

void git_remote_set_update_fetchhead(git_remote *remote, int value);

int git_remote_is_valid_name(const(char)* remote_name);

+/