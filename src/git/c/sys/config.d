module git.c.sys.config;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.config;
import git.c.types;

extern (C):

/**
 * @file git2/sys/config.h
 * @brief Git config backend routines
 * @defgroup git_backend Git custom backend APIs
 * @ingroup Git
 * @{
 */


/**
 * Every iterator must have this struct as its first element, so the
 * API can talk to it. You'd define your iterator as
 *
 *     struct my_iterator {
 *             git_config_iterator parent;
 *             ...
 *     }
 *
 * and assign `iter->parent.backend` to your `git_config_backend`.
 */
struct git_config_iterator {
	git_config_backend *backend;
	uint flags;

	/**
	 * Return the current entry and advance the iterator. The
	 * memory belongs to the library.
	 */
	int function(git_config_entry **entry, git_config_iterator *iter) next;

	/**
	 * Free the iterator
	 */
	void function(git_config_iterator *iter) free;
}

/**
 * Generic backend that implements the interface to
 * access a configuration file
 */
struct git_config_backend {
	uint version_ = GIT_CONFIG_BACKEND_VERSION;
	git_config *cfg;

	/* Open means open the file/database and parse if necessary */
	int function(git_config_backend *, git_config_level_t level) open;
	int function(const(git_config_backend)*, const(char)* key, const(git_config_entry)** entry) get;
	int function(git_config_backend *, const(char)* key, const(char)* value) set;
	int function(git_config_backend *cfg, const(char)* name, const(char)* regexp, const(char)* value) set_multivar;
	int function(git_config_backend *, const(char)* key) del;
	int function(struct git_config_backend *, const char *key, const char *regexp) del_multivar;
	int function(git_config_iterator **, struct git_config_backend *) iterator;
	int function(git_config_backend *) refresh;
	void function(git_config_backend *) free;
}

enum GIT_CONFIG_BACKEND_VERSION = 1;
enum git_config_backend GIT_CONFIG_BACKEND_INIT = { GIT_CONFIG_BACKEND_VERSION };

/**
 * Add a generic config file instance to an existing config
 *
 * Note that the configuration object will free the file
 * automatically.
 *
 * Further queries on this config object will access each
 * of the config file instances in order (instances with
 * a higher priority level will be accessed first).
 *
 * @param cfg the configuration to add the file to
 * @param file the configuration file (backend) to add
 * @param level the priority level of the backend
 * @param force if a config file already exists for the given
 *  priority level, replace it
 * @return 0 on success, GIT_EEXISTS when adding more than one file
 *  for a given priority level (and force_replace set to 0), or error code
 */
int git_config_add_backend(
	git_config *cfg,
	git_config_backend *file,
	git_config_level_t level,
	int force);



//#endif
