/*
 *             Copyright David Nadlinger 2014.
 *              Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.remote;

import git.oid;
import git.repository;
import git.net;
import git.types;
import git.util;
import git.version_;

import deimos.git2.net;
import deimos.git2.oid;
import deimos.git2.remote;
import deimos.git2.types;

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
enum GitRemoteCompletionType {
    download = GIT_REMOTE_COMPLETION_DOWNLOAD,
    indexing = GIT_REMOTE_COMPLETION_INDEXING,
    error = GIT_REMOTE_COMPLETION_ERROR,
}

///
struct GitRemoteCallbacks {
    void delegate(string str) progress;
    void delegate(GitRemoteCompletionType type) completion;
    //void delegate(GitCred *cred, string url, string username_from_url, uint allowed_types) credentials;
    TransferCallbackDelegate transferProgress;
}

alias GitUpdateTipsDelegate = void delegate(string refname, in ref GitOid a, in ref GitOid b);


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

    @property GitTransferProgress stats()
    {
        return GitTransferProgress(git_remote_stats(_data._payload));
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
    void download(TransferCallbackDelegate progressCallback)
    {
        GitRemoteCallbacks cb;
        cb.transferProgress = progressCallback;
        download(&cb);
    }
    ///
    void download(GitRemoteCallbacks* callbacks = null)
    {
        assert(connected, "Must connect(GitDirection.push) before invoking download().");

        git_remote_callbacks gitcallbacks;
        gitcallbacks.progress = &progress_cb;
        gitcallbacks.completion = &completion_cb;
        static if (targetLibGitVersion >= VersionInfo(0, 20, 0)) {
            //gitcallbacks.credentials = &cred_acquire_cb;
            gitcallbacks.transfer_progress = &transfer_progress_cb;
        }
        gitcallbacks.payload = cast(void*)callbacks;
        require(git_remote_set_callbacks(_data._payload, &gitcallbacks) == 0);

        static if (targetLibGitVersion == VersionInfo(0, 19, 0)) {
            require(git_remote_download(_data._payload, &transfer_progress_cb, cast(void*)callbacks) == 0);
        } else {
            require(git_remote_download(_data._payload) == 0);
        }
    }

    void updateTips(scope void delegate(string refname, in ref GitOid a, in ref GitOid b) updateTips)
    {
        static struct CTX { GitUpdateTipsDelegate updateTips; }

        static extern(C) nothrow int update_cb(const(char)* refname, const(git_oid)* a, const(git_oid)* b, void* payload)
        {
            auto cbs = cast(CTX*)payload;
            if (cbs.updateTips) {
                try {
                    auto ac = GitOid(*a);
                    auto bc = GitOid(*b);
                    cbs.updateTips(refname.to!string, ac, bc);
                } catch (Exception e) return -1;
            }
            return 0;
        }

        CTX ctx;
        ctx.updateTips = updateTips;

        git_remote_callbacks gitcallbacks;
        gitcallbacks.update_tips = &update_cb;
        gitcallbacks.payload = &ctx;
        require(git_remote_set_callbacks(_data._payload, &gitcallbacks) == 0);
        require(git_remote_update_tips(_data._payload) == 0);
    }

    immutable(GitRemoteHead)[] ls()
    {
        static if (targetLibGitVersion == VersionInfo(0, 19, 0)) {
            static struct CTX { immutable(GitRemoteHead)[] heads; }

            static extern(C) int callback(git_remote_head* rhead, void* payload) {
                auto ctx = cast(CTX*)payload;
                ctx.heads ~= GitRemoteHead(rhead);
                return 0;
            }

            CTX ctx;
            require(git_remote_ls(this.cHandle, &callback, &ctx) == 0);
            return ctx.heads;
        } else {
            const(git_remote_head)** heads;
            size_t head_count;
            require(git_remote_ls(&heads, &head_count, _data._payload) == 0);
            auto ret = new GitRemoteHead[head_count];
            foreach (i, ref rh; ret) ret[i] = GitRemoteHead(heads[i]);
            return cast(immutable)ret;
        }
    }

    package inout(git_remote)* cHandle() inout { return _data._payload; }

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


private extern(C) nothrow {
    static if (targetLibGitVersion == VersionInfo(0, 19, 0)) {
        void progress_cb(const(char)* str, int len, void* payload)
        {
            auto cbs = cast(GitRemoteCallbacks*)payload;
            if (cbs.progress) {
                try cbs.progress(str[0 .. len].idup);
                catch (Exception e) {} // FIXME: store exception and skip calling the callback during the next iterations
            }
        }
    } else {
        int progress_cb(const(char)* str, int len, void* payload)
        {
            auto cbs = cast(GitRemoteCallbacks*)payload;
            if (cbs.progress) {
                try cbs.progress(str[0 .. len].idup);
                catch (Exception e) return -1; // FIXME: store and rethrow exception 
            }
            return 0;
        }
    }

    /*int cred_acquire_cb(git_cred** dst, const(char)* url, const(char)* username_from_url, uint allowed_types, void* payload)
    {
        auto cbs = cast(GitRemoteCallbacks)payload;
        try cbs.credentials(...);
        catch (Exception e) return -1; // FIXME: store and rethrow exception 
        return 0;
    }*/

    int completion_cb(git_remote_completion_type type, void* payload)
    {
        auto cbs = cast(GitRemoteCallbacks*)payload;
        if (cbs.completion) {
            try cbs.completion(cast(GitRemoteCompletionType)type);
            catch (Exception e) return -1; // FIXME: store and rethrow exception 
        }
        return 0;
    }

    int transfer_progress_cb(const(git_transfer_progress)* stats, void* payload)
    {
        auto cbs = cast(GitRemoteCallbacks*)payload;
        if (cbs.transferProgress) {
            try {
                auto tp = GitTransferProgress(stats);
                cbs.transferProgress(tp);
            } catch (Exception e) return -1; // FIXME: store and rethrow exception 
        }
        return 0;
    }
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