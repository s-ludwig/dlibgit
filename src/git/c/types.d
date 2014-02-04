module git.c.types;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/types.h
 * @brief libgit2 base & compatibility types
 * @ingroup Git
 * @{
 */

import core.stdc.stdint;

alias int32_t = core.stdc.stdint.int32_t;
alias int64_t = core.stdc.stdint.int64_t;
alias uint16_t = core.stdc.stdint.uint16_t;
alias uint32_t = core.stdc.stdint.uint32_t;

alias off64_t = long;
alias __time64_t = long;
alias __int64 = long;
alias __haiku_std_int64 = long;

import std.conv;

import git.c.common;
import git.c.util;

extern (C):

/**
 * Cross-platform compatibility types for off_t / time_t
 *
 * NOTE: This needs to be in a public header so that both the library
 * implementation and client applications both agree on the same types.
 * Otherwise we get undefined behavior.
 *
 * Use the "best" types that each platform provides. Currently we truncate
 * these intermediate representations for compatibility with the git ABI, but
 * if and when it changes to support 64 bit types, our code will naturally
 * adapt.
 * NOTE: These types should match those that are returned by our internal
 * stat() functions, for all platforms.
 */

alias git_off_t = long;
alias git_time_t = long;

/** Basic type (loose or packed) of any Git object. */
enum git_otype
{
	GIT_OBJ_ANY = -2,		/**< Object can be any of the following */
	GIT_OBJ_BAD = -1,		/**< Object is invalid. */
	GIT_OBJ__EXT1 = 0,		/**< Reserved for future use. */
	GIT_OBJ_COMMIT = 1,		/**< A commit object. */
	GIT_OBJ_TREE = 2,		/**< A tree (directory listing) object. */
	GIT_OBJ_BLOB = 3,		/**< A file revision object. */
	GIT_OBJ_TAG = 4,		/**< An annotated tag object. */
	GIT_OBJ__EXT2 = 5,		/**< Reserved for future use. */
	GIT_OBJ_OFS_DELTA = 6, /**< A delta, base is given by an offset. */
	GIT_OBJ_REF_DELTA = 7, /**< A delta, base is given by object id. */
}

mixin _ExportEnumMembers!git_otype;

/** An open object database handle. */
struct git_odb
{
    @disable this();
    @disable this(this);
}

/** An object read from the ODB */
struct git_odb_object
{
    @disable this();
    @disable this(this);
}

/** An open refs database handle. */
struct git_refdb
{
    @disable this();
    @disable this(this);
}

/**
 * Representation of an existing git repository,
 * including all its object contents
 */
struct git_repository
{
    @disable this();
    @disable this(this);
}

/** Representation of a generic object in a repository */
struct git_object
{
    @disable this();
    @disable this(this);
}

/** Representation of an in-progress walk through the commits in a repo */
struct git_revwalk
{
    @disable this();
    @disable this(this);
}

/** Parsed representation of a tag object. */
struct git_tag
{
    @disable this();
    @disable this(this);
}

/** In-memory representation of a blob object. */
struct git_blob
{
    @disable this();
    @disable this(this);
}

/** Parsed representation of a commit object. */
struct git_commit
{
    @disable this();
    @disable this(this);
}

/** Representation of each one of the entries in a tree object. */
struct git_tree_entry
{
    @disable this();
    @disable this(this);
}

/** Representation of a tree object. */
struct git_tree
{
    @disable this();
    @disable this(this);
}

/** Constructor for in-memory trees */
struct git_treebuilder
{
    @disable this();
    @disable this(this);
}

/** Memory representation of an index file. */
struct git_index
{
    @disable this();
    @disable this(this);
}

/** An interator for conflicts in the index. */
struct git_index_conflict_iterator
{
    @disable this();
    @disable this(this);
}

/** Memory representation of a set of config files */
struct git_config
{
    @disable this();
    @disable this(this);
}

/** Representation of a reference log entry */
struct git_reflog_entry
{
    @disable this();
    @disable this(this);
}

/** Representation of a reference log */
struct git_reflog
{
    @disable this();
    @disable this(this);
}

/** Representation of a git note */
struct git_note
{
    @disable this();
    @disable this(this);
}

/** Representation of a git packbuilder */
struct git_packbuilder
{
    @disable this();
    @disable this(this);
}

/** Time in a signature */
struct git_time
{
	git_time_t time; /** time in seconds from epoch */
	int offset; /** timezone offset, in minutes */
}

/** An action signature (e.g. for committers, taggers, etc) */
struct git_signature
{
	char *name; /** full name of the author */
	char *email; /** email of the author */
	git_time when; /** time when the action happened */
}

/** In-memory representation of a reference. */
struct git_reference
{
    @disable this();
    @disable this(this);
}

/** Merge heads, the input to merge */
struct git_merge_head
{
    @disable this();
    @disable this(this);
}

/** Merge result */
struct git_merge_result
{
    @disable this();
    @disable this(this);
}

/** Representation of a status collection */
struct git_status_list
{
    @disable this();
    @disable this(this);
}

/** Basic type of any Git reference. */
enum git_ref_t
{
	GIT_REF_INVALID = 0, /** Invalid reference */
	GIT_REF_OID = 1, /** A reference which points at an object id */
	GIT_REF_SYMBOLIC = 2, /** A reference which points at another reference */
	GIT_REF_LISTALL = GIT_REF_OID|GIT_REF_SYMBOLIC,
}

mixin _ExportEnumMembers!git_ref_t;

/** Basic type of any Git branch. */
enum git_branch_t
{
	GIT_BRANCH_LOCAL = 1,
	GIT_BRANCH_REMOTE = 2,
}

mixin _ExportEnumMembers!git_branch_t;

/** Valid modes for index and tree entries. */
enum git_filemode_t
{
	GIT_FILEMODE_NEW					= octal!0,
	GIT_FILEMODE_TREE					= octal!40000,
	GIT_FILEMODE_BLOB					= octal!100644,
	GIT_FILEMODE_BLOB_EXECUTABLE		= octal!100755,
	GIT_FILEMODE_LINK					= octal!120000,
	GIT_FILEMODE_COMMIT					= octal!160000,
}

mixin _ExportEnumMembers!git_filemode_t;

struct git_refspec
{
    @disable this();
    @disable this(this);
}

struct git_remote
{
    @disable this();
    @disable this(this);
}

struct git_push
{
    @disable this();
    @disable this(this);
}

/**
 * This is passed as the first argument to the callback to allow the
 * user to see the progress.
 *
 * - total_objects: number of objects in the packfile being downloaded
 * - indexed_objects: received objects that have been hashed
 * - received_objects: objects which have been downloaded
 * - local_objects: locally-available objects that have been injected
 *    in order to fix a thin pack.
 * - received-bytes: size of the packfile received up to now
 */
struct git_transfer_progress
{
	uint total_objects;
	uint indexed_objects;
	uint received_objects;
    uint local_objects;
    uint total_deltas;
    uint indexed_deltas;
	size_t received_bytes;
}

/**
 * Type for progress callbacks during indexing.  Return a value less than zero
 * to cancel the transfer.
 *
 * @param stats Structure containing information about the state of the transfer
 * @param payload Payload provided by caller
 */
alias git_transfer_progress_callback = int function(const(git_transfer_progress)* stats, void* payload);

/**
 * Opaque structure representing a submodule.
 */
struct git_submodule
{
    @disable this();
    @disable this(this);
}

/**
 * Submodule update values
 *
 * These values represent settings for the `submodule.$name.update`
 * configuration value which says how to handle `git submodule update` for
 * this submodule.  The value is usually set in the ".gitmodules" file and
 * copied to ".git/config" when the submodule is initialized.
 *
 * You can override this setting on a per-submodule basis with
 * `git_submodule_set_update()` and write the changed value to disk using
 * `git_submodule_save()`.  If you have overwritten the value, you can
 * revert it by passing `GIT_SUBMODULE_UPDATE_RESET` to the set function.
 *
 * The values are:
 *
 * - GIT_SUBMODULE_UPDATE_RESET: reset to the on-disk value.
 * - GIT_SUBMODULE_UPDATE_CHECKOUT: the default; when a submodule is
 *   updated, checkout the new detached HEAD to the submodule directory.
 * - GIT_SUBMODULE_UPDATE_REBASE: update by rebasing the current checked
 *   out branch onto the commit from the superproject.
 * - GIT_SUBMODULE_UPDATE_MERGE: update by merging the commit in the
 *   superproject into the current checkout out branch of the submodule.
 * - GIT_SUBMODULE_UPDATE_NONE: do not update this submodule even when
 *   the commit in the superproject is updated.
 * - GIT_SUBMODULE_UPDATE_DEFAULT: not used except as static initializer
 *   when we don't want any particular update rule to be specified.
 */
enum git_submodule_update_t {
    GIT_SUBMODULE_UPDATE_RESET    = -1,

    GIT_SUBMODULE_UPDATE_CHECKOUT = 1,
    GIT_SUBMODULE_UPDATE_REBASE   = 2,
    GIT_SUBMODULE_UPDATE_MERGE    = 3,
    GIT_SUBMODULE_UPDATE_NONE     = 4,

    GIT_SUBMODULE_UPDATE_DEFAULT  = 0
}

/**
 * Submodule ignore values
 *
 * These values represent settings for the `submodule.$name.ignore`
 * configuration value which says how deeply to look at the working
 * directory when getting submodule status.
 *
 * You can override this value in memory on a per-submodule basis with
 * `git_submodule_set_ignore()` and can write the changed value to disk
 * with `git_submodule_save()`.  If you have overwritten the value, you
 * can revert to the on disk value by using `GIT_SUBMODULE_IGNORE_RESET`.
 *
 * The values are:
 *
 * - GIT_SUBMODULE_IGNORE_RESET: reset to the on-disk value.
 * - GIT_SUBMODULE_IGNORE_NONE: don't ignore any change - i.e. even an
 *   untracked file, will mark the submodule as dirty.  Ignored files are
 *   still ignored, of course.
 * - GIT_SUBMODULE_IGNORE_UNTRACKED: ignore untracked files; only changes
 *   to tracked files, or the index or the HEAD commit will matter.
 * - GIT_SUBMODULE_IGNORE_DIRTY: ignore changes in the working directory,
 *   only considering changes if the HEAD of submodule has moved from the
 *   value in the superproject.
 * - GIT_SUBMODULE_IGNORE_ALL: never check if the submodule is dirty
 * - GIT_SUBMODULE_IGNORE_DEFAULT: not used except as static initializer
 *   when we don't want any particular ignore rule to be specified.
 */
enum git_submodule_ignore_t {
    GIT_SUBMODULE_IGNORE_RESET     = -1, /* reset to on-disk value */

    GIT_SUBMODULE_IGNORE_NONE      = 1,  /* any change or untracked == dirty */
    GIT_SUBMODULE_IGNORE_UNTRACKED = 2,  /* dirty if tracked files change */
    GIT_SUBMODULE_IGNORE_DIRTY     = 3,  /* only dirty if HEAD moved */
    GIT_SUBMODULE_IGNORE_ALL       = 4,  /* never dirty */

    GIT_SUBMODULE_IGNORE_DEFAULT   = 0
}
