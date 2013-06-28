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
 *
 * @return 0 or an error code
 */
int git_odb_backend_loose(git_odb_backend **out_, const(char)* objects_dir, int compression_level, int do_fsync);

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

/** A stream to read/write from a backend */
struct git_odb_stream {
	git_odb_backend *backend;
	uint mode;

	int  function(git_odb_stream *stream, char *buffer, size_t len) read;
	int  function(git_odb_stream *stream, const(char)* buffer, size_t len) write;
	int  function(git_oid *oid_p, git_odb_stream *stream) finalize_write;
	void function(git_odb_stream *stream) free;
}

/** A stream to write a pack file to the ODB */
struct git_odb_writepack
{
	git_odb_backend *backend;

	int  function(git_odb_writepack *writepack, const(void)* data, size_t size, git_transfer_progress *stats) add;
	int  function(git_odb_writepack *writepack, git_transfer_progress *stats) commit;
	void function(git_odb_writepack *writepack) free;
}




