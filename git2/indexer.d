module git2.indexer;

import git2.oid;

extern(C):

struct git_transfer_progress {
	uint total_objects;
	uint indexed_objects;
	uint received_objects;
	size_t received_bytes;
}

alias git_transfer_progress_callback = void function(const git_transfer_progress *stats, void *payload);

struct git_indexer { }

struct git_indexer_stream { }

void git_indexer_free(git_indexer* idx);
const(git_oid)* git_indexer_hash(git_indexer* idx);
int git_indexer_new(git_indexer** _out, const(char)* packname);
int git_indexer_run(git_indexer* idx, git_transfer_progress* stats);
int git_indexer_stream_add(git_indexer_stream* idx, const(void)* data, size_t size, git_transfer_progress* stats);
int git_indexer_stream_finalize(git_indexer_stream* idx, git_transfer_progress* stats);
void git_indexer_stream_free(git_indexer_stream* idx);
const(git_oid)* git_indexer_stream_hash(git_indexer_stream* idx);
int git_indexer_stream_new(git_indexer_stream** _out, const(char)* path);
int git_indexer_write(git_indexer* idx);
