/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.common;

// todo: port more of these from git.c.common

import git.c.common;

package
{
    version(Windows)
        enum GitPathSep = ";";
    else
        enum GitPathSep = ":";
}

/**
 * The maximum length of a valid git path.
 */
enum MaxGitPathLen = GIT_PATH_MAX;

/**
 * The string representation of the null object ID.
 */
enum GitOid_HexZero = GIT_OID_HEX_ZERO;

//~ /**
 //~ * Combinations of these values describe the capabilities of libgit2.
 //~ */
//~ enum git_cap_t
//~ {
	//~ GIT_CAP_THREADS			= ( 1 << 0 ),
	//~ GIT_CAP_HTTPS			= ( 1 << 1 )
//~ }

//~ /**
 //~ * Query compile time options for libgit2.
 //~ *
 //~ * @return A combination of GIT_CAP_* values.
 //~ *
 //~ * - GIT_CAP_THREADS
 //~ *   Libgit2 was compiled with thread support. Note that thread support is
 //~ *   still to be seen as a 'work in progress' - basic object lookups are
 //~ *   believed to be threadsafe, but other operations may not be.
 //~ *
 //~ * - GIT_CAP_HTTPS
 //~ *   Libgit2 supports the https:// protocol. This requires the openssl
 //~ *   library to be found when compiling libgit2.
 //~ */
//~ int git_libgit2_capabilities();

//~ enum git_libgit2_opt_t
//~ {
	//~ GIT_OPT_GET_MWINDOW_SIZE,
	//~ GIT_OPT_SET_MWINDOW_SIZE,
	//~ GIT_OPT_GET_MWINDOW_MAPPED_LIMIT,
	//~ GIT_OPT_SET_MWINDOW_MAPPED_LIMIT,
	//~ GIT_OPT_GET_SEARCH_PATH,
	//~ GIT_OPT_SET_SEARCH_PATH,
	//~ GIT_OPT_SET_CACHE_OBJECT_LIMIT,
	//~ GIT_OPT_SET_CACHE_MAX_SIZE,
	//~ GIT_OPT_ENABLE_CACHING,
	//~ GIT_OPT_GET_CACHED_MEMORY
//~ }

//~ /**
 //~ * Set or query a library global option
 //~ *
 //~ * Available options:
 //~ *
 //~ *	* opts(GIT_OPT_GET_MWINDOW_SIZE, size_t *):
 //~ *
 //~ *		> Get the maximum mmap window size
 //~ *
 //~ *	* opts(GIT_OPT_SET_MWINDOW_SIZE, size_t):
 //~ *
 //~ *		> Set the maximum mmap window size
 //~ *
 //~ *	* opts(GIT_OPT_GET_MWINDOW_MAPPED_LIMIT, size_t *):
 //~ *
 //~ *		> Get the maximum memory that will be mapped in total by the library
 //~ *
 //~ *	* opts(GIT_OPT_SET_MWINDOW_MAPPED_LIMIT, size_t):
 //~ *
 //~ *		>Set the maximum amount of memory that can be mapped at any time
 //~ *		by the library
 //~ *
 //~ *	* opts(GIT_OPT_GET_SEARCH_PATH, int level, char *out, size_t len)
 //~ *
 //~ *		> Get the search path for a given level of config data.  "level" must
 //~ *		> be one of `GIT_CONFIG_LEVEL_SYSTEM`, `GIT_CONFIG_LEVEL_GLOBAL`, or
 //~ *		> `GIT_CONFIG_LEVEL_XDG`.  The search path is written to the `out`
 //~ *		> buffer up to size `len`.  Returns GIT_EBUFS if buffer is too small.
 //~ *
 //~ *	* opts(GIT_OPT_SET_SEARCH_PATH, int level, const(char)* path)
 //~ *
 //~ *		> Set the search path for a level of config data.  The search path
 //~ *		> applied to shared attributes and ignore files, too.
 //~ *		>
 //~ *		> - `path` lists directories delimited by GIT_PATH_LIST_SEPARATOR.
 //~ *		>   Pass NULL to reset to the default (generally based on environment
 //~ *		>   variables).  Use magic path `$PATH` to include the old value
 //~ *		>   of the path (if you want to prepend or append, for instance).
 //~ *		>
 //~ *		> - `level` must be GIT_CONFIG_LEVEL_SYSTEM, GIT_CONFIG_LEVEL_GLOBAL,
 //~ *		>   or GIT_CONFIG_LEVEL_XDG.
 //~ *
 //~ *	* opts(GIT_OPT_SET_CACHE_OBJECT_LIMIT, git_otype type, size_t size)
 //~ *
 //~ *		> Set the maximum data size for the given type of object to be
 //~ *		> considered eligible for caching in memory.  Setting to value to
 //~ *		> zero means that that type of object will not be cached.
 //~ *		> Defaults to 0 for GIT_OBJ_BLOB (i.e. won't cache blobs) and 4k
 //~ *		> for GIT_OBJ_COMMIT, GIT_OBJ_TREE, and GIT_OBJ_TAG.
 //~ *
 //~ *	* opts(GIT_OPT_SET_CACHE_MAX_SIZE, ssize_t max_storage_bytes)
 //~ *
 //~ *		> Set the maximum total data size that will be cached in memory
 //~ *		> across all repositories before libgit2 starts evicting objects
 //~ *		> from the cache.  This is a soft limit, in that the library might
 //~ *		> briefly exceed it, but will start aggressively evicting objects
 //~ *		> from cache when that happens.  The default cache size is 256Mb.
 //~ *
 //~ *	* opts(GIT_OPT_ENABLE_CACHING, int enabled)
 //~ *
 //~ *		> Enable or disable caching completely.
 //~ *		>
 //~ *		> Because caches are repository-specific, disabling the cache
 //~ *		> cannot immediately clear all cached objects, but each cache will
 //~ *		> be cleared on the next attempt to update anything in it.
 //~ *
 //~ *	* opts(GIT_OPT_GET_CACHED_MEMORY, ssize_t *current, ssize_t *allowed)
 //~ *
 //~ *		> Get the current bytes in cache and the maximum that would be
 //~ *		> allowed in the cache.
 //~ *
 //~ * @param option Option key
 //~ * @param ... value to set the option
 //~ * @return 0 on success, <0 on failure
 //~ */
//~ int git_libgit2_opts(int option, ...);
