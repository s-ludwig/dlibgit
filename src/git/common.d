/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.common;

// todo: port more of these from git.c.common

package
{
    version(Windows)
        enum GitPathSep = ";";
    else
        enum GitPathSep = ":";
}
