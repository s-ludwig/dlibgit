/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.util;

/**
    Contains utility functions for this package.
*/

import std.array;
import std.conv;
import std.exception;
import std.string;

import git.c.errors;

import git.exception;

/**
    Require the result to be either 1 or 0. If it is, return the boolean value,
    otherwise throw a GitException.
*/
package bool requireBool(int result, string file = __FILE__, size_t line = __LINE__)
{
    require(result == 0 || result == 1);
    return result == 1;
}

/**
    Call this function when an error code is returned from a git function.
    It will retrieve the last error and throw a GitException.

    $(RED Note:) assert or in blocks should be used to verify arguments (such as strings)
    before calling Git functions since Git itself does not check pointers for null.
    Passing null pointers to Git functions usually results in access violations.
*/
package void require(bool state, string file = __FILE__, size_t line = __LINE__)
{
    if (state)
        return;

    const(git_error)* gitError = giterr_last();

    enforce(gitError !is null,
        "Error: No Git error thrown, error condition check is likely invalid.");

    const msg = format("Git error (%s): %s.", cast(git_error_t)gitError.klass, to!string(gitError.message));

    giterr_clear();
    throw new GitException(msg, file, line);
}

///
unittest
{
    import git.c.oid;
    git_oid oid;
    assertThrown!GitException(require(git_oid_fromstr(&oid, "foobar") == 0));
}

/** Return a posix-native path, replacing back slashes with forward slashes. */
string toPosixPath(string input)
{
    return input.replace(r"\", "/");
}

///
unittest
{
    assert(r"foo/bar\doo".toPosixPath == r"foo/bar/doo");
}
