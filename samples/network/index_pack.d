module index_pack;

import git.c;

import std.stdio;
import std.exception;

// This could be run in the main loop while the application waits for
// the indexing to finish in a worker thread
int index_cb(const git_indexer_stats* stats, void* data)
{
    writefln("\rProcessing %s of %s", stats.processed, stats.total);
    return 0;
}

int run_index_pack(git_repository* repo, int argc, string[] argv)
{
    git_indexer_stream* idx;
    git_indexer_stats stats;
    int error;
    int fd;
    char[GIT_OID_HEXSZ + 1] hash = '\0';
    byte[512] buf;

    if (argc < 2)
    {
        writeln("I need a packfile\n");
        return -1;
    }

    if (git_indexer_stream_new(&idx, ".git") < 0)
    {
        writeln("bad idx");
        return -1;
    }

    scope(exit)
        git_indexer_stream_free(idx);

    File file = File(argv[1], "r");

    while (1)
    {
        byte[] read_bytes = file.rawRead(buf);

        enforce(git_indexer_stream_add(idx, read_bytes.ptr, read_bytes.length, &stats) >= 0);
        printf("\rIndexing %d of %d", stats.processed, stats.total);

        if (read_bytes.length < buf.length)
            break;
    }

    enforce(git_indexer_stream_finalize(idx, &stats) >= 0);

    writefln("\nIndexing %d of %d", stats.processed, stats.total);

    git_oid_fmt(hash.ptr, git_indexer_stream_hash(idx));
    writefln("Hash: %s\n", hash);
    return 0;
}

int index_pack_old(git_repository* repo, int argc, char** argv)
{
    git_indexer* indexer;
    git_indexer_stats stats;
    int  error;
    char[GIT_OID_HEXSZ + 1] hash;

    if (argc < 2)
    {
        writeln("I need a packfile\n");
        return -1;
    }

    // Create a new indexer
    error = git_indexer_new(&indexer, argv[1]);

    if (error < 0)
        return error;

    // Index the packfile. This function can take a very long time and
    // should be run in a worker thread.
    error = git_indexer_run(indexer, &stats);

    if (error < 0)
        return error;

    // Write the information out to an index file
    error = git_indexer_write(indexer);

    // Get the packfile's hash (which should become it's filename)
    git_oid_fmt(hash.ptr, git_indexer_hash(indexer));
    writeln(hash);

    git_indexer_free(indexer);

    return 0;
}
