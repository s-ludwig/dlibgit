module git.c.sys.odb_backend;

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
import git.c.odb;
import git.c.odb_backend;

/**
 * @file git2/sys/backend.h
 * @brief Git custom backend implementors functions
 * @defgroup git_backend Git custom backend APIs
 * @ingroup Git
 * @{
 */


/**
 * An instance for a custom backend
 */
struct git_odb_backend {
	uint version_;
	git_odb *odb;

	/* read and read_prefix each return to libgit2 a buffer which
	 * will be freed later. The buffer should be allocated using
	 * the function git_odb_backend_malloc to ensure that it can
	 * be safely freed later. */
	int function(
		void **, size_t *, git_otype *, git_odb_backend *, const(git_oid)* ) read;

	/* To find a unique object given a prefix
	 * of its oid.
	 * The oid given must be so that the
	 * remaining (GIT_OID_HEXSZ - len)*4 bits
	 * are 0s.
	 */
	int function(
		git_oid *, void **, size_t *, git_otype *,
		git_odb_backend *, const(git_oid)* , size_t) read_prefix;

	int function(
		size_t *, git_otype *, git_odb_backend *, const(git_oid)* ) read_header;

	/* The writer may assume that the object
	 * has already been hashed and is passed
	 * in the first parameter.
	 */
	int function(
		git_oid *, git_odb_backend *, const(void)* , size_t, git_otype) write;

	int function(
		git_odb_stream **, git_odb_backend *, size_t, git_otype) writestream;

	int function(
		git_odb_stream **, git_odb_backend *, const(git_oid)* ) readstream;

	int function(
		git_odb_backend *, const(git_oid)* ) exists;

	int function(git_odb_backend *) refresh;

	int function(
		git_odb_backend *, git_odb_foreach_cb cb, void *payload) foreach_;

	int function(
		git_odb_writepack **, git_odb_backend *,
		git_transfer_progress_callback progress_cb, void *progress_payload) writepack;

	void function(git_odb_backend *) free;
}

enum GIT_ODB_BACKEND_VERSION = 1;
enum git_odb_backend GIT_ODB_BACKEND_INIT = { GIT_ODB_BACKEND_VERSION };

void * git_odb_backend_malloc(git_odb_backend *backend, size_t len);



//#endif
