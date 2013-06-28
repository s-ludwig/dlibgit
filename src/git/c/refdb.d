module git.c.refdb;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/refdb.h
 * @brief Git custom refs backend functions
 * @defgroup git_refdb Git custom refs backend API
 * @ingroup Git
 * @{
 */

import git.c.common;
import git.c.oid;
import git.c.refs;
import git.c.types;

extern (C):

/**
 * Create a new reference database with no backends.
 *
 * Before the Ref DB can be used for read/writing, a custom database
 * backend must be manually set using `git_refdb_set_backend()`
 *
 * @param out location to store the database pointer, if opened.
 *			Set to NULL if the open failed.
 * @param repo the repository
 * @return 0 or an error code
 */
int git_refdb_new(git_refdb **out_, git_repository *repo);

/**
 * Create a new reference database and automatically add
 * the default backends:
 *
 *  - git_refdb_dir: read and write loose and packed refs
 *      from disk, assuming the repository dir as the folder
 *
 * @param out location to store the database pointer, if opened.
 *			Set to NULL if the open failed.
 * @param repo the repository
 * @return 0 or an error code
 */
int git_refdb_open(git_refdb **out_, git_repository *repo);

/**
 * Suggests that the given refdb compress or optimize its references.
 * This mechanism is implementation specific.  For on-disk reference
 * databases, for example, this may pack all loose references.
 */
int git_refdb_compress(git_refdb *refdb);

/**
 * Close an open reference database.
 *
 * @param refdb reference database pointer or NULL
 */
void git_refdb_free(git_refdb *refdb);





