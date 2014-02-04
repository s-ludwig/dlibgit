module git.c.odb_backend;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/backend.h
 * @brief Git custom backend functions
 * @defgroup git_odb Git object database routines
 * @ingroup Git
 * @{
 */

import git.c.common;
import git.c.oid;
import git.c.sys.odb_backend;
import git.c.util;
import git.c.types;

extern (C):

/*
 * Constructors for in-box ODB backends.
 */

/**
 * Create a backend for the packfiles.
 *
 * @param out location to store the odb backend pointer
 * @param objects_dir the Git repository's objects directory
 *
 * @return 0 or an error code
 */
int git_odb_backend_pack(git_odb_backend **out_, const(char)* objects_dir);

/**
 * Create a backend for loose objects
 *
 * @param out location to store the odb backend pointer
 * @param objects_dir the Git repository's objects directory
 * @param compression_level zlib compression level to use
 * @param do_fsync whether to do an fsync() after writing (currently ignored)
 * @param dir_mode permissions to use creating a directory or 0 for defaults
 * @param file_mode permissions to use creating a file or 0 for defaults
 *
 * @return 0 or an error code
 */
int git_odb_backend_loose(
	git_odb_backend **out_,
	const(char)* objects_dir,
	int compression_level,
	int do_fsync,
	uint dir_mode,
	uint file_mode);

/**
 * Create a backend out of a single packfile
 *
 * This can be useful for inspecting the contents of a single
 * packfile.
 *
 * @param out location to store the odb backend pointer
 * @param index_file path to the packfile's .idx file
 *
 * @return 0 or an error code
 */
int git_odb_backend_one_pack(git_odb_backend **out_, const(char)* index_file);

/** Streaming mode */
enum git_odb_stream_t {
	GIT_STREAM_RDONLY = (1 << 1),
	GIT_STREAM_WRONLY = (1 << 2),
	GIT_STREAM_RW = (GIT_STREAM_RDONLY | GIT_STREAM_WRONLY),
} ;

mixin _ExportEnumMembers!git_odb_stream_t;

/**
 * A stream to read/write from a backend.
 *
 * This represents a stream of data being written to or read from a
 * backend. When writing, the frontend functions take care of
 * calculating the object's id and all `finalize_write` needs to do is
 * store the object with the id it is passed.
 */
struct git_odb_stream {
	git_odb_backend *backend;
	uint mode;
	void *hash_ctx;

	size_t declared_size;
	size_t received_bytes;

	/**
	 * Write at most `len` bytes into `buffer` and advance the stream.
	 */
	int function(git_odb_stream *stream, char *buffer, size_t len) read;

	/**
	 * Write `len` bytes from `buffer` into the stream.
	 */
	int function(git_odb_stream *stream, const(char)* buffer, size_t len) write;

	/**
	 * Store the contents of the stream as an object with the id
	 * specified in `oid`.
	 *
	 * This method might not be invoked if:
	 * - an error occurs earlier with the `write` callback,
	 * - the object referred to by `oid` already exists in any backend, or
	 * - the final number of received bytes differs from the size declared
	 *   with `git_odb_open_wstream()`
	 */
	int function(git_odb_stream *stream, const(git_oid)* oid) finalize_write;

	/**
	 * Free the stream's memory.
	 *
	 * This method might be called without a call to `finalize_write` if
	 * an error occurs or if the object is already present in the ODB.
	 */
	void function(git_odb_stream *stream) free;
};

/** A stream to write a pack file to the ODB */
struct git_odb_writepack
{
	git_odb_backend *backend;

	int  function(git_odb_writepack *writepack, const(void)* data, size_t size, git_transfer_progress *stats) append;
	int  function(git_odb_writepack *writepack, git_transfer_progress *stats) commit;
	void function(git_odb_writepack *writepack) free;
}




