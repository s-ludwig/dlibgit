/*
 *    Copyright Andrej Mitrovic 2013, David Nadlinger 2014.
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
import std.datetime;
import std.exception;
import std.string;

import deimos.git2.errors;
import deimos.git2.types : git_time;

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
    import deimos.git2.oid;
    git_oid oid;
    assertThrown!GitException(require(git_oid_fromstr(&oid, "foobar") == 0));
}

/** Return a posix-native path, replacing backslashes with forward slashes. */
string toPosixPath(string input)
{
    return input.replace(`\`, `/`);
}

///
unittest
{
    assert(`foo/bar\doo`.toPosixPath == r"foo/bar/doo");
}

alias toSlice = to!(const(char)[]);

SysTime toSysTime(git_time gtime)
{
    auto ctime = unixTimeToStdTime(gtime.time);
    auto ctimeoff = gtime.offset.minutes();
    return SysTime(ctime, new immutable SimpleTimeZone(ctimeoff));
}

git_time toGitTime(SysTime time)
{
    git_time ret;
    ret.time = stdTimeToUnixTime(time.stdTime);
    ret.offset = cast(int)((time.timezone.utcToTZ(time.stdTime) - time.stdTime) / (10_000_000*60));
    return ret;
}

// TODO: unit tests for time functions!


/**
    Converts the passed char slice to a C string, returning the null pointer for
    empty strings.

    libgit2 generally only switches to the default for optional string
    parameters if they are null, vs. just the empty string.
*/
const(char)* gitStr(const(char)[] s)
{
    import std.conv : toStringz;
    return s.length ? s.toStringz : null;
}

mixin template RefCountedGitObject(T, alias free_function, bool define_chandle = true)
{
public:
    bool opCast(T)() const if (is(T == bool)) { return cHandle !is null; }

package:
    static if (define_chandle) {
        @property inout(T)* cHandle() inout { return _data._payload; }
    }

private:
    struct Payload
    {
        this(T* payload)
        {
            _payload = payload;
        }

        ~this()
        {
            if (_payload !is null)
            {
                free_function(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        T* _payload;
    }

    import std.typecons : RefCounted, RefCountedAutoInitialize;
    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;
}
