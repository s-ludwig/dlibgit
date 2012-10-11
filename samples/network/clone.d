module clone;

import git2.all;

import core.thread;
import std.concurrency;
import std.string;
import std.stdio;

import common;

void clone_thread()
{
    git_repository* repo = null;

    // Kick off the clone
    clone_data.ret = git_clone(&repo, toStringz(clone_data.url), toStringz(clone_data.path),
                         &clone_data.fetch_stats, &clone_data.checkout_stats,
                         &clone_data.opts);

    if (repo)
        git_repository_free(repo);
    
    clone_data.finished = 1;
}

int do_clone(git_repository* repo, int argc, string[] args)
{
    // Validate args
    if (argc < 3) 
    {
        writefln("USAGE: %s <url> <path>\n", args[0]);
        return -1;
    }

    // Data for background thread
    clone_data.url = args[1];
    clone_data.path = args[2];
    clone_data.opts.disable_filters = 1;
    writefln("Cloning '%s' to '%s'", clone_data.url, clone_data.path);

    // Create the worker thread
    spawn(&clone_thread);
    
    // Watch for progress information
    do {
        Thread.sleep(dur!("msecs")(100));
        writefln("Fetch %s/%s  –  Checkout %s/%s",
        clone_data.fetch_stats.processed, clone_data.fetch_stats.total,
        clone_data.checkout_stats.processed, clone_data.checkout_stats.total);
    } while (!clone_data.finished);

    writefln("Fetch %s/%s  –  Checkout %s/%s",
    clone_data.fetch_stats.processed, clone_data.fetch_stats.total,
    clone_data.checkout_stats.processed, clone_data.checkout_stats.total);

    return clone_data.ret;
}
