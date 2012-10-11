module common;

import git2.all;

struct fetch_dl_data
{
    git_remote* remote;
    git_off_t* bytes;
    git_indexer_stats* stats;
    int ret;
    int finished;
};

struct clone_dl_data
{
    git_indexer_stats fetch_stats;
    git_indexer_stats checkout_stats;
    git_checkout_opts opts;
    int ret;
    int finished;
    string url;
    string path;
}

// temporary until we figure out a safe alternative
__gshared clone_dl_data clone_data;
__gshared fetch_dl_data fetch_data;

alias int function(git_repository*, int, string[]) git_cb;
