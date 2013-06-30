/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.version_;

import std.string;

import git.c.version_;

/**
    Version information of $(LIBGIT2)
    which this binding is based on.
*/
struct LibGitVersion
{
    /// Text representation of version, e.g. "0.19.1"
    enum string text = LIBGIT2_VERSION;

    /// Major version, e.g. 0.19.1 -> 0
    enum int major = LIBGIT2_VER_MAJOR;

    /// Minor version, e.g. 0.19.1 -> 19
    enum int minor = LIBGIT2_VER_MINOR;

    /// Revision version, e.g. 0.19.1 -> 1
    enum int revision = LIBGIT2_VER_REVISION;
}

/**
    Version information of the $(D dlibgit) binding.
    $(RED Note:) The $(D dlibgit) version specification
    is separate from the $(LIBGIT2) version.
*/
struct DLibGitVersion
{
    /// Text representation of version, e.g. "0.19.1"
    enum string text = format("%s.%s.%s", major, minor, revision);

    /// Major version, e.g. 0.19.1 -> 0
    enum int major = 0;

    /// Minor version, e.g. 0.19.1 -> 19
    enum int minor = 1;

    /// Revision version, e.g. 0.19.1 -> 1
    enum int revision = 0;
}

/// The libgit2 version this binding is based on
static assert(LibGitVersion.text == "0.19.0");

/// The version of the binding itself
static assert(DLibGitVersion.text == "0.1.0");
