/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.common;

// todo: port more of these from git.c.common

import std.array;
import std.conv;
import std.exception;
import std.stdio;
import std.string;
import std.traits;

import git.c.common;

import git.config;
import git.exception;
import git.util;

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

/**
    The capabilities of libgit2.
*/
struct GitFeatures
{
    /**
        Libgit2 was compiled with thread support. Note that thread support is
        still to be seen as a 'work in progress' - basic object lookups are
        believed to be threadsafe, but other operations may not be.
    */
    bool usesThreads;

    /**
        Libgit2 supports the https:// protocol. This requires the openssl
        library to be found when compiling libgit2.
    */
    bool usesSSL;
}

/**
    Get the capabilities of the runtime $(D libgit2) library.
*/
GitFeatures getLibGitFeatures()
{
    typeof(return) result;

    int flags = git_libgit2_capabilities();

    if (flags | GIT_CAP_THREADS)
        result.usesThreads = true;

    if (flags | GIT_CAP_HTTPS)
        result.usesSSL = true;

    return result;
}

///
unittest
{
    auto features = getLibGitFeatures();
    if (features.usesSSL) { }
}

/**
    Static functions to query or set global libgit2 options.
*/
struct globalOpts
{
static:
    /// Get the maximum mmap window size.
    @property size_t mwindowSize()
    {
        typeof(return) result;
        git_libgit2_opts(GIT_OPT_GET_MWINDOW_SIZE, &result);
        return result;
    }

    /// Set the maximum mmap window size.
    @property void mwindowSize(size_t size)
    {
        git_libgit2_opts(GIT_OPT_SET_MWINDOW_SIZE, size);
    }

    ///
    unittest
    {
        auto oldSize = globalOpts.mwindowSize;
        scope(exit) globalOpts.mwindowSize = oldSize;

        globalOpts.mwindowSize = 1;
        assert(globalOpts.mwindowSize == 1);
    }

    /// Get the maximum memory in bytes that will be mapped in total by the library.
    @property size_t mwindowMappedLimit()
    {
        typeof(return) result;
        git_libgit2_opts(GIT_OPT_GET_MWINDOW_MAPPED_LIMIT, &result);
        return result;
    }

    /// Set the maximum amount of memory in bytes that can be mapped at any time by the library.
    @property void mwindowMappedLimit(size_t limit)
    {
        git_libgit2_opts(GIT_OPT_SET_MWINDOW_MAPPED_LIMIT, limit);
    }

    ///
    unittest
    {
        auto oldLimit = globalOpts.mwindowMappedLimit;
        scope(exit) globalOpts.mwindowMappedLimit = oldLimit;

        globalOpts.mwindowMappedLimit = 1;
        assert(globalOpts.mwindowMappedLimit == 1);
    }

    /**
        Get the search paths for a given level of config data.

        $(B Note:) $(D configLevel) must be one of $(D GitConfigLevel.system),
        $(D GitConfigLevel.xdg), or $(D GitConfigLevel.global).
    */
    string[] getSearchPaths(GitConfigLevel configLevel)
    {
        int level = cast(int)configLevel;
        char[MaxGitPathLen] buffer;

        require(git_libgit2_opts(GIT_OPT_GET_SEARCH_PATH, level, &buffer, buffer.length) == 0);
        return to!string(buffer.ptr).split(GitPathSep);
    }

    /**
        Set the search paths for a given level of config data.

        $(B Note:) Use the magic path $(B "$PATH") to include the old value
        of the path. This is useful for prepending or appending paths.

        $(B Note:) Passing a null or empty array of paths will reset the
        paths to their defaults (based on environment variables).

        $(B Note:) $(D configLevel) must be one of $(D GitConfigLevel.system),
        $(D GitConfigLevel.xdg), or $(D GitConfigLevel.global).
    */
    void setSearchPaths(GitConfigLevel configLevel, string[] paths)
    {
        int level = cast(int)configLevel;
        const(char)* cPaths = paths.join(GitPathSep).toStringz();
        require(git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH, level, cPaths) == 0);
    }

    ///
    unittest
    {
        foreach (config; EnumMembers!GitConfigLevel)
        {
            if (config == GitConfigLevel.local
                || config == GitConfigLevel.app
                || config == GitConfigLevel.highest)
            {
                assertThrown!GitException(getSearchPaths(config));
                assertThrown!GitException(setSearchPaths(config, []));
                continue;
            }

            auto oldPaths = getSearchPaths(config);
            scope(exit) setSearchPaths(config, oldPaths);

            auto newPaths = ["/foo", "$PATH", "/foo/bar"];
            setSearchPaths(config, newPaths);

            auto chained = newPaths[0] ~ oldPaths ~ newPaths[2];
            assert(getSearchPaths(config) == chained);

            setSearchPaths(config, []);
            assert(getSearchPaths(config) == oldPaths);
        }
    }
}

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
