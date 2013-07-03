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

import git.c.errors;
import git.c.util;
import git.c.types;

import git.exception;

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
