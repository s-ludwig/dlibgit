/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.version_;

import git.c.version_;

struct GitVersion
{
    enum string Version = LIBGIT2_VERSION;
    enum int VersionMajor = LIBGIT2_VER_MAJOR;
    enum int VersionMinor = LIBGIT2_VER_MINOR;
    enum int VersionRevision = LIBGIT2_VER_REVISION;
}
