module ls_remote;

import git.c;

import std.algorithm;
import std.stdio;
import std.string;

extern(C) int show_ref__cb(git_remote_head* head, void* payload)
{
    char[GIT_OID_HEXSZ + 1] oid = '\0';
    git_oid_fmt(oid.ptr, &head.oid);
    printf("%s\t%s\n", oid.ptr, head.name);
    return 0;
}

int use_unnamed(git_repository* repo, const char* url)
{
    git_remote* remote = null;
    int error;

    // Create an instance of a remote from the URL. The transport to use
    // is detected from the URL
    error = git_remote_new(&remote, repo, null, url, null);

    if (error < 0)
        goto cleanup;

    // When connecting, the underlying code needs to know wether we
    // want to push or fetch
    error = git_remote_connect(remote, GIT_DIR_FETCH);

    if (error < 0)
        goto cleanup;

    // With git_remote_ls we can retrieve the advertised heads
    error = git_remote_ls(remote, &show_ref__cb, null);

cleanup:
    git_remote_free(remote);
    return error;
}

int use_remote(git_repository* repo, const(char)* name)
{
    git_remote* remote = null;
    int error;

    // Find the remote by name
    error = git_remote_load(&remote, repo, name);

    if (error < 0)
        goto cleanup;

    error = git_remote_connect(remote, GIT_DIR_FETCH);

    if (error < 0)
        goto cleanup;

    error = git_remote_ls(remote, &show_ref__cb, null);

cleanup:
    git_remote_free(remote);
    return error;
}

// This gets called to do the work. The remote can be given either as
// the name of a configured remote or an URL.
int run_ls_remote(git_repository* repo, int argc, string[] argv)
{
    if (argc < 2)
    {
        writeln("I need a remote.\n");
        return -1;
    }

    int error;
    int i;

    /* If there's a ':' in the name, assume it's a URL */
    if (argv[1].canFind(":"))
    {
        error = use_unnamed(repo, argv[1].toStringz);
    }
    else
    {
        error = use_remote(repo, argv[1].toStringz);
    }

    return error;
}
