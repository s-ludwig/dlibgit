module git2.indexer;

import git2.oid;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

struct git_indexer { }

struct git_indexer_stats 
{
    uint total;
    uint processed;
    uint received;
}

struct git_indexer_stream { }

void git_indexer_free(git_indexer* idx);
const(git_oid)* git_indexer_hash(git_indexer* idx);
int git_indexer_new(git_indexer** _out, const(char)* packname);
int git_indexer_run(git_indexer* idx, git_indexer_stats* stats);
int git_indexer_stream_add(git_indexer_stream* idx, const(void)* data, size_t size, git_indexer_stats* stats);
int git_indexer_stream_finalize(git_indexer_stream* idx, git_indexer_stats* stats);
void git_indexer_stream_free(git_indexer_stream* idx);
const(git_oid)* git_indexer_stream_hash(git_indexer_stream* idx);
int git_indexer_stream_new(git_indexer_stream** _out, const(char)* path);
int git_indexer_write(git_indexer* idx);
