module git.c.sys.commit;

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

/**
 * @file git2/sys/commit.h
 * @brief Low-level Git commit creation
 * @defgroup git_backend Git custom backend APIs
 * @ingroup Git
 * @{
 */


/**
 * Create new commit in the repository from a list of `git_oid` values
 *
 * See documentation for `git_commit_create()` for information about the
 * parameters, as the meaning is identical excepting that `tree` and
 * `parents` now take `git_oid`.  This is a dangerous API in that nor
 * the `tree`, neither the `parents` list of `git_oid`s are checked for
 * validity.
 */
int git_commit_create_from_oids(
	git_oid *oid,
	git_repository *repo,
	const(char)* update_ref,
	const(git_signature)* author,
	const(git_signature)* committer,
	const(char)* message_encoding,
	const(char)* message,
	const(git_oid)* tree,
	int parent_count,
	const(git_oid)* parents[]);  // array of pointer to const git_oid



//#endif
