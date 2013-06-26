module fetch;

import git2.c;

import core.thread;
import std.concurrency;
import std.string;
import std.stdio;

import common;

void download()
{
    // Connect to the remote end specifying that we want to fetch
    // information from it.
    if (git_remote_connect(fetch_data.remote, GIT_DIR_FETCH) < 0)
    {
        fetch_data.ret = -1;
        goto exit;
    }

    // Download the packfile and index it. This function updates the
    //~ // amount of received data and the indexer stats which lets you
    //~ // inform the user about progress.
    if (git_remote_download(fetch_data.remote, fetch_data.bytes, fetch_data.stats) < 0)
    {
        fetch_data.ret = -1;
        goto exit;
    }

    fetch_data.ret = 0;

exit:
    fetch_data.finished = 1;
}

int update_cb(const(char)* refname, const git_oid* a, const git_oid* b)
{
    const(char)* action;
    char[GIT_OID_HEXSZ + 1] a_str = '\0';
    char[GIT_OID_HEXSZ + 1] b_str = '\0';

    git_oid_fmt(b_str.ptr, b);
    b_str[GIT_OID_HEXSZ] = '\0';

    if (git_oid_iszero(a))
    {
        printf("[new]     %.20s %s\n", b_str, refname);
    }
    else
    {
        git_oid_fmt(a_str.ptr, a);
        a_str[GIT_OID_HEXSZ] = '\0';
        printf("[updated] %.10s..%.10s %s\n", a_str, b_str, refname);
    }

    return 0;
}

int run_fetch(git_repository* repo, int argc, string[] argv)
{
    git_remote* remote;
    git_off_t bytes    = 0;
    git_indexer_stats stats;

    // Figure out whether it's a named remote or a URL
    writefln("Fetching %s\n", argv[1]);

    if (git_remote_load(&remote, repo, argv[1].toStringz) < 0)
    {
        if (git_remote_new(&remote, repo, null, argv[1].toStringz, null) < 0)
            return -1;
    }

    // Set up the information for the background worker thread
    fetch_data.remote   = remote;
    fetch_data.bytes    = &bytes;
    fetch_data.stats    = &stats;
    fetch_data.ret      = 0;
    fetch_data.finished = 0;

    spawn(&download);

    // Loop while the worker thread is still running. Here we show processed
    // and total objects in the pack and the amount of received
    // data. Most frontends will probably want to show a percentage and
    // the download rate.
    do
    {
        Thread.sleep(dur!("msecs")(100));
        writefln("\rReceived %s/%s objects in %s bytes", stats.processed, stats.total, bytes);
    }
    while (!fetch_data.finished);

    writefln("\rReceived %s/%s objects in %s bytes", stats.processed, stats.total, bytes);

    // Disconnect the underlying connection to prevent from idling.
    git_remote_disconnect(remote);

    // Update the references in the remote's namespace to point to the
    // right commits. This may be needed even if there was no packfile
    // to download, which can happen e.g. when the branches have been
    // changed but all the neede objects are available locally.
    if (git_remote_update_tips(remote) < 0)
        return -1;

    git_remote_free(remote);

    return 0;

on_error:
    git_remote_free(remote);
    return -1;
}
