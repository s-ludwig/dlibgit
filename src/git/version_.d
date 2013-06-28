/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.version_;

import git.c.version_;

/**
    A namespace containing the version information of $(LIBGIT2)
    which this binding is based on.
*/
struct GitVersion
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
