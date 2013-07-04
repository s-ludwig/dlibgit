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
import git.c.types;

import git.config;
import git.exception;
import git.types;
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

/** Memory caching mode for libgit2. */
enum CacheMode
{
    ///
    disabled,

    ///
    enabled
}

/**
    Static functions with which to query or set global libgit2 options.
*/
struct globalOptions
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
        auto oldSize = globalOptions.mwindowSize;
        scope(exit) globalOptions.mwindowSize = oldSize;

        globalOptions.mwindowSize = 1;
        assert(globalOptions.mwindowSize == 1);
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
        auto oldLimit = globalOptions.mwindowMappedLimit;
        scope(exit) globalOptions.mwindowMappedLimit = oldLimit;

        globalOptions.mwindowMappedLimit = 1;
        assert(globalOptions.mwindowMappedLimit == 1);
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
            if (config != GitConfigLevel.system
                && config != GitConfigLevel.xdg
                && config != GitConfigLevel.global)
            {
                assertThrown!GitException(getSearchPaths(config));
                assertThrown!GitException(setSearchPaths(config, []));
                continue;
            }
            else
            {
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

    /**
        Set the maximum data size for the given type of object to be
        considered eligible for caching in memory.  Setting to value to
        zero means that that type of object will not be cached.

        Defaults to 0 for $(D GitType.blob) (i.e. won't cache blobs) and 4k
        for $(D GitType.commit), $(D GitType.tree), and $(D GitType.tag).
    */
    void setCacheObjectLimit(GitType type, size_t size)
    {
        require(git_libgit2_opts(GIT_OPT_SET_CACHE_OBJECT_LIMIT, cast(git_otype)type, size) == 0);
    }

    ///
    unittest
    {
        setCacheObjectLimit(GitType.commit, 4096);
    }

    /**
        Set the maximum total data size that will be cached in memory
        across all repositories before libgit2 starts evicting objects
        from the cache.  This is a soft limit, in that the library might
        briefly exceed it, but will start aggressively evicting objects
        from cache when that happens.

        The default cache size is 256Mb.
    */
    void setCacheMaxSize(ptrdiff_t maxStorageBytes)
    {
        require(git_libgit2_opts(GIT_OPT_SET_CACHE_MAX_SIZE, maxStorageBytes) == 0);
    }

    /** Return the default cache size - 256Mb. */
    @property ptrdiff_t defaultCacheMaxSize()
    {
        return 256 * 1024 * 1024;
    }

    ///
    unittest
    {
        setCacheMaxSize(defaultCacheMaxSize);
    }

    /**
        Enable or disable caching completely.

        Since caches are repository-specific, disabling the cache
        cannot immediately clear all the cached objects, but each cache
        will be cleared on the next attempt to update anything in it.
    */
    void setCacheMode(CacheMode mode)
    {
        require(git_libgit2_opts(GIT_OPT_ENABLE_CACHING, cast(int)mode) == 0);
    }

    ///
    unittest
    {
        setCacheMode(CacheMode.disabled);
        setCacheMode(CacheMode.enabled);
    }

    /** The cache status of libgit2. */
    struct CacheMemory
    {
        /// current bytes in the cache.
        ptrdiff_t currentSize;

        /// the maximum bytes allowed in the cache.
        ptrdiff_t maxSize;
    }

    /** Get the current status of the cache. */
    CacheMemory getCacheMemory()
    {
        ptrdiff_t current;
        ptrdiff_t allowed;
        require(git_libgit2_opts(GIT_OPT_GET_CACHED_MEMORY, &current, &allowed) == 0);

        return CacheMemory(current, allowed);
    }

    ///
    unittest
    {
        auto cache = getCacheMemory();
    }

    /// alternate spelling
    alias getCachedMemory = getCacheMemory;
}
