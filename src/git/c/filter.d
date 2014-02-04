module git.c.filter;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.types;
import git.c.oid;
import git.c.buffer;

/**
 * @file git2/filter.h
 * @brief Git filter APIs
 *
 * @ingroup Git
 * @{
 */

/**
 * Filters are applied in one of two directions: smudging - which is
 * exporting a file from the Git object database to the working directory,
 * and cleaning - which is importing a file from the working directory to
 * the Git object database.  These values control which direction of
 * change is being applied.
 */
enum git_filter_mode_t {
	GIT_FILTER_TO_WORKTREE = 0,
	GIT_FILTER_SMUDGE = GIT_FILTER_TO_WORKTREE,
	GIT_FILTER_TO_ODB = 1,
	GIT_FILTER_CLEAN = GIT_FILTER_TO_ODB,
}

/**
 * A filter that can transform file data
 *
 * This represents a filter that can be used to transform or even replace
 * file data.  Libgit2 includes one built in filter and it is possible to
 * write your own (see git2/sys/filter.h for information on that).
 *
 * The two builtin filters are:
 *
 * * "crlf" which uses the complex rules with the "text", "eol", and
 *   "crlf" file attributes to decide how to convert between LF and CRLF
 *   line endings
 * * "ident" which replaces "$Id$" in a blob with "$Id: <blob OID>$" upon
 *   checkout and replaced "$Id: <anything>$" with "$Id$" on checkin.
 */
struct git_filter {
	@disable this();
	@disable this(this);
}

/**
 * List of filters to be applied
 *
 * This represents a list of filters to be applied to a file / blob.  You
 * can build the list with one call, apply it with another, and dispose it
 * with a third.  In typical usage, there are not many occasions where a
 * git_filter_list is needed directly since the library will generally
 * handle conversions for you, but it can be convenient to be able to
 * build and apply the list sometimes.
 */
struct git_filter_list {
	@disable this();
	@disable this(this);
}

/**
 * Load the filter list for a given path.
 *
 * This will return 0 (success) but set the output git_filter_list to NULL
 * if no filters are requested for the given file.
 *
 * @param filters Output newly created git_filter_list (or NULL)
 * @param repo Repository object that contains `path`
 * @param blob The blob to which the filter will be applied (if known)
 * @param path Relative path of the file to be filtered
 * @param mode Filtering direction (WT->ODB or ODB->WT)
 * @return 0 on success (which could still return NULL if no filters are
 *         needed for the requested file), $(LT)0 on error
 */
int git_filter_list_load(
	git_filter_list **filters,
	git_repository *repo,
	git_blob *blob, /* can be NULL */
	const(char)* path,
	git_filter_mode_t mode);

/**
 * Apply filter list to a data buffer.
 *
 * See `git2/buffer.h` for background on `git_buf` objects.
 *
 * If the `in` buffer holds data allocated by libgit2 (i.e. `in->asize` is
 * not zero), then it will be overwritten when applying the filters.  If
 * not, then it will be left untouched.
 *
 * If there are no filters to apply (or `filters` is NULL), then the `out`
 * buffer will reference the `in` buffer data (with `asize` set to zero)
 * instead of allocating data.  This keeps allocations to a minimum, but
 * it means you have to be careful about freeing the `in` data since `out`
 * may be pointing to it!
 *
 * @param out Buffer to store the result of the filtering
 * @param filters A loaded git_filter_list (or NULL)
 * @param in Buffer containing the data to filter
 * @return 0 on success, an error code otherwise
 */
int git_filter_list_apply_to_data(
	git_buf *out_,
	git_filter_list *filters,
	git_buf *in_);

/**
 * Apply filter list to the contents of a file on disk
 */
int git_filter_list_apply_to_file(
	git_buf *out_,
	git_filter_list *filters,
	git_repository *repo,
	const(char)* path);

/**
 * Apply filter list to the contents of a blob
 */
int git_filter_list_apply_to_blob(
	git_buf *out_,
	git_filter_list *filters,
	git_blob *blob);

/**
 * Free a git_filter_list
 *
 * @param filters A git_filter_list created by `git_filter_list_load`
 */
void git_filter_list_free(git_filter_list *filters);
