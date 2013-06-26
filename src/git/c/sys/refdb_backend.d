module git.c.sys.refdb_backend;

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
 * @file git2/refdb_backend.h
 * @brief Git custom refs backend functions
 * @defgroup git_refdb_backend Git custom refs backend API
 * @ingroup Git
 * @{
 */



/**
 * Every backend's iterator must have a pointer to itself as the first
 * element, so the API can talk to it. You'd define your iterator as
 *
 *     struct my_iterator {
 *             git_reference_iterator parent;
 *             ...
 *     }
 *
 * and assign `iter->parent.backend` to your `git_refdb_backend`.
 */
struct git_reference_iterator {
	git_refdb *db;

	/**
	 * Return the current reference and advance the iterator.
	 */
	int function(
		git_reference **ref_,
		git_reference_iterator *iter) next;

	/**
	 * Return the name of the current reference and advance the iterator
	 */
	int function(
		const(char)** ref_name,
		git_reference_iterator *iter) next_name;

	/**
	 * Free the iterator
	 */
	void function(
		git_reference_iterator *iter) free;
}

/** An instance for a custom backend */
struct git_refdb_backend {
	uint version_;

	/**
	 * Queries the refdb backend to determine if the given ref_name
	 * exists.  A refdb implementation must provide this function.
	 */
	int function(
		int *exists,
		git_refdb_backend *backend,
		const(char)* ref_name) exists;

	/**
	 * Queries the refdb backend for a given reference.  A refdb
	 * implementation must provide this function.
	 */
	int function(
		git_reference **out_,
		git_refdb_backend *backend,
		const(char)* ref_name) lookup;

	/**
	 * Allocate an iterator object for the backend.
	 *
	 * A refdb implementation must provide this function.
	 */
	int function(
		git_reference_iterator **iter,
		git_refdb_backend *backend,
		const(char)* glob) iterator;

	/*
	 * Writes the given reference to the refdb.  A refdb implementation
	 * must provide this function.
	 */
	int function(git_refdb_backend *backend,
		const(git_reference)* ref_, int force) write;

	int function(
		git_reference **out_, git_refdb_backend *backend,
		const(char)* old_name, const(char)* new_name, int force) rename;

	/**
	 * Deletes the given reference from the refdb.  A refdb implementation
	 * must provide this function.
	 */
	int function(git_refdb_backend *backend, const(char)* ref_name) delete_;

	/**
	 * Suggests that the given refdb compress or optimize its references.
	 * This mechanism is implementation specific.  (For on-disk reference
	 * databases, this may pack all loose references.)    A refdb
	 * implementation may provide this function; if it is not provided,
	 * nothing will be done.
	 */
	int function(git_refdb_backend *backend) compress;

	/**
	 * Frees any resources held by the refdb.  A refdb implementation may
	 * provide this function; if it is not provided, nothing will be done.
	 */
	void function(git_refdb_backend *backend) free;
}

enum GIT_ODB_BACKEND_VERSION = 1;
enum git_refdb_backend GIT_ODB_BACKEND_INIT = { GIT_ODB_BACKEND_VERSION };

/**
 * Constructors for default filesystem-based refdb backend
 *
 * Under normal usage, this is called for you when the repository is
 * opened / created, but you can use this to explicitly construct a
 * filesystem refdb backend for a repository.
 *
 * @param backend_out Output pointer to the git_refdb_backend object
 * @param repo Git repository to access
 * @return 0 on success, <0 error code on failure
 */
int git_refdb_backend_fs(
	git_refdb_backend **backend_out,
	git_repository *repo);

/**
 * Sets the custom backend to an existing reference DB
 *
 * The `git_refdb` will take ownership of the `git_refdb_backend` so you
 * should NOT free it after calling this function.
 *
 * @param refdb database to add the backend to
 * @param backend pointer to a git_refdb_backend instance
 * @return 0 on success; error code otherwise
 */
int git_refdb_set_backend(
	git_refdb *refdb,
	git_refdb_backend *backend);



//#endif
