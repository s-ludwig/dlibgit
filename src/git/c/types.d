module git.c.types;

import git.c.common;

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

/** An open object database handle. */
struct git_odb;

/** An object read from the ODB */
struct git_odb_object;

/** An open refs database handle. */
struct git_refdb;

/**
 * Representation of an existing git repository,
 * including all its object contents
 */
struct git_repository;

/** Representation of a generic object in a repository */
struct git_object;

/** Representation of an in-progress walk through the commits in a repo */
struct git_revwalk;

/** Parsed representation of a tag object. */
struct git_tag;

/** In-memory representation of a blob object. */
struct git_blob;

/** Parsed representation of a commit object. */
struct git_commit;

/** Representation of each one of the entries in a tree object. */
struct git_tree_entry;

/** Representation of a tree object. */
struct git_tree;

/** Constructor for in-memory trees */
struct git_treebuilder;

/** Memory representation of an index file. */
struct git_index;

/** An interator for conflicts in the index. */
struct git_index_conflict_iterator;

/** Memory representation of a set of config files */
struct git_config;

/** Representation of a reference log entry */
struct git_reflog_entry;

/** Representation of a reference log */
struct git_reflog;

/** Representation of a git note */
struct git_note;

/** Representation of a git packbuilder */
struct git_packbuilder;

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
struct git_reference;

/** Merge heads, the input to merge */
struct git_merge_head;

/** Representation of a status collection */
struct git_status_list;


/** Basic type of any Git reference. */
enum git_ref_t
{
	GIT_REF_INVALID = 0, /** Invalid reference */
	GIT_REF_OID = 1, /** A reference which points at an object id */
	GIT_REF_SYMBOLIC = 2, /** A reference which points at another reference */
	GIT_REF_LISTALL = GIT_REF_OID|GIT_REF_SYMBOLIC,
}

/** Basic type of any Git branch. */
enum git_branch_t
{
	GIT_BRANCH_LOCAL = 1,
	GIT_BRANCH_REMOTE = 2,
}

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

struct git_refspec;
struct git_remote;
struct git_push;

/**
 * This is passed as the first argument to the callback to allow the
 * user to see the progress.
 */
struct git_transfer_progress
{
	uint total_objects;
	uint indexed_objects;
	uint received_objects;
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
