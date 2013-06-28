module git.c.stash;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/stash.h
 * @brief Git stash management routines
 * @ingroup Git
 * @{
 */

import git.c.common;
import git.c.oid;
import git.c.types;

extern (C):

enum git_stash_flags {
	GIT_STASH_DEFAULT = 0,

	/* All changes already added to the index
	 * are left intact in the working directory
	 */
	GIT_STASH_KEEP_INDEX = (1 << 0),

	/* All untracked files are also stashed and then
	 * cleaned up from the working directory
	 */
	GIT_STASH_INCLUDE_UNTRACKED = (1 << 1),

	/* All ignored files are also stashed and then
	 * cleaned up from the working directory
	 */
	GIT_STASH_INCLUDE_IGNORED = (1 << 2),
} ;

/**
 * Save the local modifications to a new stash.
 *
 * @param out Object id of the commit containing the stashed state.
 * This commit is also the target of the direct reference refs/stash.
 *
 * @param repo The owning repository.
 *
 * @param stasher The identity of the person performing the stashing.
 *
 * @param message Optional description along with the stashed state.
 *
 * @param flags Flags to control the stashing process. (see GIT_STASH_* above)
 *
 * @return 0 on success, GIT_ENOTFOUND where there's nothing to stash,
 * or error code.
 */
int git_stash_save(
	git_oid *out_,
	git_repository *repo,
	git_signature *stasher,
	const(char)* message,
	uint flags);

/**
 * When iterating over all the stashed states, callback that will be
 * issued per entry.
 *
 * @param index The position within the stash list. 0 points to the
 * most recent stashed state.
 *
 * @param message The stash message.
 *
 * @param stash_id The commit oid of the stashed state.
 *
 * @param payload Extra parameter to callback function.
 *
 * @return 0 on success, GIT_EUSER on non-zero callback, or error code
 */
alias git_stash_cb = int function(
	size_t index,
	const(char)* message,
	const(git_oid)* stash_id,
	void *payload);

/**
 * Loop over all the stashed states and issue a callback for each one.
 *
 * If the callback returns a non-zero value, this will stop looping.
 *
 * @param repo Repository where to find the stash.
 *
 * @param callback Callback to invoke per found stashed state. The most recent
 * stash state will be enumerated first.
 *
 * @param payload Extra parameter to callback function.
 *
 * @return 0 on success, GIT_EUSER on non-zero callback, or error code
 */
int git_stash_foreach(
	git_repository *repo,
	git_stash_cb callback,
	void *payload);

/**
 * Remove a single stashed state from the stash list.
 *
 * @param repo The owning repository.
 *
 * @param index The position within the stash list. 0 points to the
 * most recent stashed state.
 *
 * @return 0 on success, or error code
 */

int git_stash_drop(
	git_repository *repo,
	size_t index);




