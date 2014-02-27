/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.version_;

import std.exception;
import std.string;

import deimos.git2.common;
import deimos.git2.version_;

import git.common;

/**
    Contains version information.
*/
struct VersionInfo
{
    ///
    this(int major, int minor, int revision)
    {
        this.major = major;
        this.minor = minor;
        this.revision = revision;
        this.text = format("%s.%s.%s", major, minor, revision);
    }

    ///
    this(int major, int minor, int revision, string text)
    {
        this.major = major;
        this.minor = minor;
        this.revision = revision;
        this.text = text;
    }

    /// Major version, e.g. 0.19.1 -> 0
    int major;

    /// Minor version, e.g. 0.19.1 -> 19
    int minor;

    /// Revision version, e.g. 0.19.1 -> 1
    int revision;

    /// Text representation of version, e.g. "0.19.1"
    string text;

    string toString()
    {
        return format("v%s", text);
    }

    int opCmp(in ref VersionInfo other)
    const {
        if (this.major != other.major) return this.major - other.major;
        if (this.minor != other.minor) return this.minor - other.minor;
        if (this.revision != other.revision) return this.revision - other.revision;
        return 0;
    }
}

/**
    Target version this binding is based on.
*/
enum targetLibGitVersion = VersionInfo(LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION, LIBGIT2_VERSION);

/**
    The current version of dlibgit.
*/
enum dlibgitVersion = VersionInfo(0, 1, 0);


static assert(targetLibGitVersion == VersionInfo(0, 19, 0) || targetLibGitVersion == VersionInfo(0, 20, 0));

/**
    Return the runtime version of the libgit2 library
    that has been linked with.
*/
VersionInfo getLibGitVersion()
{
    int major;
    int minor;
    int revision;
    git_libgit2_version(&major, &minor, &revision);

    return VersionInfo(major, minor, revision);
}

shared static this()
{
    verifyCompatibleLibgit();
}

/**
    Verify at runtime that the loaded version of libgit is the
    one supported by this version of dlibgit, and that it
    has features which are required by dlibgit.
*/
void verifyCompatibleLibgit()
{
    auto libgitVersion = getLibGitVersion();
    enforce(libgitVersion == targetLibGitVersion,
            format("Error: dlibgit (%s) requires libgit2 (%s).\nCurrently loaded libgit2 version is (%s).",
                   dlibgitVersion, targetLibGitVersion, libgitVersion));

    auto features = getLibGitFeatures();
    enforce(features.usesSSL, "Error: dlibgit requires libgit2 compiled with SSL support.");
}
