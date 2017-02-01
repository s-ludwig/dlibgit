/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.types;

import std.array;
import std.conv;
import std.exception;
import std.string;

import deimos.git2.common;
import deimos.git2.errors;
import deimos.git2.types;
import deimos.git2.util;

import git.exception;
import git.version_;

/** Basic type (loose or packed) of any Git object. */
enum GitType
{
    /// Object can be any of the following types.
    any        = GIT_OBJ_ANY,

    /// Object is invalid.
    bad        = GIT_OBJ_BAD,

    /// Reserved for future use.
    ext1       = GIT_OBJ__EXT1,

    /// A commit object.
    commit     = GIT_OBJ_COMMIT,

    /// A tree (directory listing) object.
    tree       = GIT_OBJ_TREE,

    /// A file revision object.
    blob       = GIT_OBJ_BLOB,

    /// An annotated tag object.
    tag        = GIT_OBJ_TAG,

    /// Reserved for future use.
    ext2       = GIT_OBJ__EXT2,

    /// A delta, base is given by an offset.
    ofs_delta  = GIT_OBJ_OFS_DELTA,

    /// A delta, base is given by object id.
    ref_delta  = GIT_OBJ_REF_DELTA
}

/** Basic type of any Git reference. */
enum GitRefType
{
    /** Invalid reference. */
    invalid = GIT_REF_INVALID,

    /** A reference which points at an object id. */
    oid = GIT_REF_OID,

    /** A reference which points at another reference. */
    symbolic = GIT_REF_SYMBOLIC,

    list_all = GIT_REF_LISTALL,
}

/** Basic type of any Git branch. */
enum GitBranchType
{
    local = GIT_BRANCH_LOCAL,
    remote = GIT_BRANCH_REMOTE,
}

/** Valid modes for index and tree entries. */
enum GitFileModeType
{
    new_ = GIT_FILEMODE_NEW,
    tree = GIT_FILEMODE_TREE,
    blob = GIT_FILEMODE_BLOB,
    blob_exe = GIT_FILEMODE_BLOB_EXECUTABLE,
    link = GIT_FILEMODE_LINK,
    commit = GIT_FILEMODE_COMMIT,
}

/// The return type of walker callbacks.
enum ContinueWalk
{
    /// Stop walk
    no,

    /// Continue walk
    yes
}

/// The return type of walker callbacks.
enum ContinueWalkSkip
{
    /// Stop walk
    no,

    /// Continue walk
    yes,

    /// Skip the current sub tree
    skip
}

/**
 * Callback for transfer progress information during remote operations (cloning,
 * fetching).
 *
 * Generally called in-line with network operations, take care not to degrade
 * performance.
 */
struct GitTransferProgress
{
    package this(const(git_transfer_progress)* p)
    {
        this.tupleof = (*p).tupleof;
    }

    uint totalObjects;
    uint indexedObjects;
    uint receivedObjects;
    static if (targetLibGitVersion == VersionInfo(0, 25, 1)) {
        uint local_objects;
        uint total_deltas;
        uint indexed_deltas;
    }
    size_t receivedBytes;
}

/// ditto
alias TransferCallbackDelegate = void delegate(const ref GitTransferProgress stats);
