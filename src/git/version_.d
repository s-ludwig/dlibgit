/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.version_;

import std.exception;
import std.string;

import git.c.common;
import git.c.version_;

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
}

/**
    Target version this binding is based on.
*/
enum targetLibGitVersion = VersionInfo(LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION, LIBGIT2_VERSION);

/**
    The current version of dlibgit.
*/
enum dlibgitVersion = VersionInfo(0, 1, 0);

/// The libgit2 version this binding is based on
static assert(targetLibGitVersion.text == "0.19.0");

/// The version of the binding itself
static assert(dlibgitVersion.text == "0.1.0");

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
