module git.c.indexer;

extern (C):

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.types;
import git.c.oid;



struct git_indexer_stream;

/**
 * Create a new streaming indexer instance
 *
 * @param out where to store the indexer instance
 * @param path to the directory where the packfile should be stored
 * @param progress_cb function to call with progress information
 * @param progress_cb_payload payload for the progress callback
 */
int git_indexer_stream_new(
		git_indexer_stream **out_,
		const(char)* path,
		git_transfer_progress_callback progress_cb,
		void *progress_cb_payload);

/**
 * Add data to the indexer
 *
 * @param idx the indexer
 * @param data the data to add
 * @param size the size of the data in bytes
 * @param stats stat storage
 */
int git_indexer_stream_add(git_indexer_stream *idx, const(void)* data, size_t size, git_transfer_progress *stats);

/**
 * Finalize the pack and index
 *
 * Resolve any pending deltas and write out the index file
 *
 * @param idx the indexer
 */
int git_indexer_stream_finalize(git_indexer_stream *idx, git_transfer_progress *stats);

/**
 * Get the packfile's hash
 *
 * A packfile's name is derived from the sorted hashing of all object
 * names. This is only correct after the index has been finalized.
 *
 * @param idx the indexer instance
 */
const(git_oid)*  git_indexer_stream_hash(const(git_indexer_stream)* idx);

/**
 * Free the indexer and its resources
 *
 * @param idx the indexer to free
 */
void git_indexer_stream_free(git_indexer_stream *idx);





