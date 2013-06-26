module git.c.sys.index;

extern (C):

import git.c.oid;
import git.c.types;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/sys/index.h
 * @brief Low-level Git index manipulation routines
 * @defgroup git_backend Git custom backend APIs
 * @ingroup Git
 * @{
 */


/** Representation of a rename conflict entry in the index. */
struct git_index_name_entry {
	char *ancestor;
	char *ours;
	char *theirs;
} ;

/** Representation of a resolve undo entry in the index. */
struct git_index_reuc_entry {
	uint[3] mode;
	git_oid[3] oid;
	char *path;
} ;

/** @name Conflict Name entry functions
 *
 * These functions work on rename conflict entries.
 */
/**@{*/

/**
 * Get the count of filename conflict entries currently in the index.
 *
 * @param index an existing index object
 * @return integer of count of current filename conflict entries
 */
uint git_index_name_entrycount(git_index *index);

/**
 * Get a filename conflict entry from the index.
 *
 * The returned entry is read-only and should not be modified
 * or freed by the caller.
 *
 * @param index an existing index object
 * @param n the position of the entry
 * @return a pointer to the filename conflict entry; NULL if out of bounds
 */
const(git_index_name_entry)*  git_index_name_get_byindex(
	git_index *index, size_t n);

/**
 * Record the filenames involved in a rename conflict.
 *
 * @param index an existing index object
 * @param ancestor the path of the file as it existed in the ancestor
 * @param ours the path of the file as it existed in our tree
 * @param theirs the path of the file as it existed in their tree
 */
int git_index_name_add(git_index *index,
	const(char)* ancestor, const(char)* ours, const(char)* theirs);

/**
 * Remove all filename conflict entries.
 *
 * @param index an existing index object
 * @return 0 or an error code
 */
void git_index_name_clear(git_index *index);

/**@}*/

/** @name Resolve Undo (REUC) index entry manipulation.
 *
 * These functions work on the Resolve Undo index extension and contains
 * data about the original files that led to a merge conflict.
 */
/**@{*/

/**
 * Get the count of resolve undo entries currently in the index.
 *
 * @param index an existing index object
 * @return integer of count of current resolve undo entries
 */
uint git_index_reuc_entrycount(git_index *index);

/**
 * Finds the resolve undo entry that points to the given path in the Git
 * index.
 *
 * @param at_pos the address to which the position of the reuc entry is written (optional)
 * @param index an existing index object
 * @param path path to search
 * @return 0 if found, < 0 otherwise (GIT_ENOTFOUND)
 */
int git_index_reuc_find(size_t *at_pos, git_index *index, const(char)* path);

/**
 * Get a resolve undo entry from the index.
 *
 * The returned entry is read-only and should not be modified
 * or freed by the caller.
 *
 * @param index an existing index object
 * @param path path to search
 * @return the resolve undo entry; NULL if not found
 */
const(git_index_reuc_entry)*  git_index_reuc_get_bypath(git_index *index, const(char)* path);

/**
 * Get a resolve undo entry from the index.
 *
 * The returned entry is read-only and should not be modified
 * or freed by the caller.
 *
 * @param index an existing index object
 * @param n the position of the entry
 * @return a pointer to the resolve undo entry; NULL if out of bounds
 */
const(git_index_reuc_entry)*  git_index_reuc_get_byindex(git_index *index, size_t n);

/**
 * Adds a resolve undo entry for a file based on the given parameters.
 *
 * The resolve undo entry contains the OIDs of files that were involved
 * in a merge conflict after the conflict has been resolved.  This allows
 * conflicts to be re-resolved later.
 *
 * If there exists a resolve undo entry for the given path in the index,
 * it will be removed.
 *
 * This method will fail in bare index instances.
 *
 * @param index an existing index object
 * @param path filename to add
 * @param ancestor_mode mode of the ancestor file
 * @param ancestor_id oid of the ancestor file
 * @param our_mode mode of our file
 * @param our_id oid of our file
 * @param their_mode mode of their file
 * @param their_id oid of their file
 * @return 0 or an error code
 */
int git_index_reuc_add(git_index *index, const(char)* path,
	int ancestor_mode, const(git_oid)* ancestor_id,
	int our_mode, const(git_oid)* our_id,
	int their_mode, const(git_oid)* their_id);

/**
 * Remove an resolve undo entry from the index
 *
 * @param index an existing index object
 * @param n position of the resolve undo entry to remove
 * @return 0 or an error code
 */
int git_index_reuc_remove(git_index *index, size_t n);

/**
 * Remove all resolve undo entries from the index
 *
 * @param index an existing index object
 * @return 0 or an error code
 */
void git_index_reuc_clear(git_index *index);

/**@}*/



//#endif
