/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.checkout;

import git.c.checkout;

import git.c.common;
import git.c.diff;
import git.c.strarray;
import git.c.types;
import git.c.util;

/**
 * Checkout behavior flags
 *
 * In libgit2, checkout is used to update the working directory and index
 * to match a target tree.  Unlike git checkout, it does not move the HEAD
 * commit for you - use `git_repository_set_head` or the like to do that.
 *
 * Checkout looks at (up to) four things: the "target" tree you want to
 * check out, the "baseline" tree of what was checked out previously, the
 * working directory for actual files, and the index for staged changes.
 *
 * You give checkout one of four strategies for update:
 *
 * - `GIT_CHECKOUT_NONE` is a dry-run strategy that checks for conflicts,
 *   etc., but doesn't make any actual changes.
 *
 * - `GIT_CHECKOUT_FORCE` is at the opposite extreme, taking any action to
 *   make the working directory match the target (including potentially
 *   discarding modified files).
 *
 * In between those are `GIT_CHECKOUT_SAFE` and `GIT_CHECKOUT_SAFE_CREATE`
 * both of which only make modifications that will not lose changes.
 *
 *                      |  target == baseline   |  target != baseline  |
 * ---------------------|-----------------------|----------------------|
 *  workdir == baseline |       no action       |  create, update, or  |
 *                      |                       |     delete file      |
 * ---------------------|-----------------------|----------------------|
 *  workdir exists and  |       no action       |   conflict (notify   |
 *    is != baseline    | notify dirty MODIFIED | and cancel checkout) |
 * ---------------------|-----------------------|----------------------|
 *   workdir missing,   | create if SAFE_CREATE |     create file      |
 *   baseline present   | notify dirty DELETED  |                      |
 * ---------------------|-----------------------|----------------------|
 *
 * The only difference between SAFE and SAFE_CREATE is that SAFE_CREATE
 * will cause a file to be checked out if it is missing from the working
 * directory even if it is not modified between the target and baseline.
 *
 *
 * To emulate `git checkout`, use `GIT_CHECKOUT_SAFE` with a checkout
 * notification callback (see below) that displays information about dirty
 * files.  The default behavior will cancel checkout on conflicts.
 *
 * To emulate `git checkout-index`, use `GIT_CHECKOUT_SAFE_CREATE` with a
 * notification callback that cancels the operation if a dirty-but-existing
 * file is found in the working directory.  This core git command isn't
 * quite "force" but is sensitive about some types of changes.
 *
 * To emulate `git checkout -f`, use `GIT_CHECKOUT_FORCE`.
 *
 * To emulate `git clone` use `GIT_CHECKOUT_SAFE_CREATE` in the options.
 *
 *
 * There are some additional flags to modify the behavior of checkout:
 *
 * - GIT_CHECKOUT_ALLOW_CONFLICTS makes SAFE mode apply safe file updates
 *   even if there are conflicts (instead of cancelling the checkout).
 *
 * - GIT_CHECKOUT_REMOVE_UNTRACKED means remove untracked files (i.e. not
 *   in target, baseline, or index, and not ignored) from the working dir.
 *
 * - GIT_CHECKOUT_REMOVE_IGNORED means remove ignored files (that are also
 *   untracked) from the working directory as well.
 *
 * - GIT_CHECKOUT_UPDATE_ONLY means to only update the content of files that
 *   already exist.  Files will not be created nor deleted.  This just skips
 *   applying adds, deletes, and typechanges.
 *
 * - GIT_CHECKOUT_DONT_UPDATE_INDEX prevents checkout from writing the
 *   updated files' information to the index.
 *
 * - Normally, checkout will reload the index and git attributes from disk
 *   before any operations.  GIT_CHECKOUT_NO_REFRESH prevents this reload.
 *
 * - Unmerged index entries are conflicts.  GIT_CHECKOUT_SKIP_UNMERGED skips
 *   files with unmerged index entries instead.  GIT_CHECKOUT_USE_OURS and
 *   GIT_CHECKOUT_USE_THEIRS to proceed with the checkout using either the
 *   stage 2 ("ours") or stage 3 ("theirs") version of files in the index.
 */
enum GitCheckoutStrategy
{
    none = GIT_CHECKOUT_NONE, /** default is a dry run, no actual updates */

    /** Allow safe updates that cannot overwrite uncommitted data */
    safe = GIT_CHECKOUT_SAFE,

    /** Allow safe updates plus creation of missing files */
    safe_create = GIT_CHECKOUT_SAFE_CREATE,

    /** Allow all updates to force working directory to look like index */
    force = GIT_CHECKOUT_FORCE,

    /** Allow checkout to make safe updates even if conflicts are found */
    allow_conflicts = GIT_CHECKOUT_ALLOW_CONFLICTS,

    /** Remove untracked files not in index (that are not ignored) */
    remove_untracked = GIT_CHECKOUT_REMOVE_UNTRACKED,

    /** Remove ignored files not in index */
    remove_ignored = GIT_CHECKOUT_REMOVE_IGNORED,

    /** Only update existing files, don't create new ones */
    update_only = GIT_CHECKOUT_UPDATE_ONLY,

    /** Normally checkout updates index entries as it goes; this stops that */
    dont_update_index = GIT_CHECKOUT_DONT_UPDATE_INDEX,

    /** Don't refresh index/config/etc before doing checkout */
    no_refresh = GIT_CHECKOUT_NO_REFRESH,

    /** Treat pathspec as simple list of exact match file paths */
    disable_pathspec_match = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH,

    /** Ignore directories in use, they will be left empty */
    skip_locked_dirs = GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES,

    /* THE FOLLOWING OPTIONS ARE NOT YET IMPLEMENTED */

    /** Allow checkout to skip unmerged files (NOT IMPLEMENTED) */
    skip_unmerged = GIT_CHECKOUT_SKIP_UNMERGED,

    /** For unmerged files, checkout stage 2 from index (NOT IMPLEMENTED) */
    use_ours = GIT_CHECKOUT_USE_OURS,

    /** For unmerged files, checkout stage 3 from index (NOT IMPLEMENTED) */
    use_theirs = GIT_CHECKOUT_USE_THEIRS,

    /** Recursively checkout submodules with same options (NOT IMPLEMENTED) */
    update_submods = GIT_CHECKOUT_UPDATE_SUBMODULES,

    /** Recursively checkout submodules if HEAD moved in super repo (NOT IMPLEMENTED) */
    update_submods_if_changed = GIT_CHECKOUT_UPDATE_SUBMODULES_IF_CHANGED,
}

/**
 * Checkout notification flags
 *
 * Checkout will invoke an options notification callback (`notify_cb`) for
 * certain cases - you pick which ones via `notify_flags`:
 *
 * - GIT_CHECKOUT_NOTIFY_CONFLICT invokes checkout on conflicting paths.
 *
 * - GIT_CHECKOUT_NOTIFY_DIRTY notifies about "dirty" files, i.e. those that
 *   do not need an update but no longer match the baseline.  Core git
 *   displays these files when checkout runs, but won't stop the checkout.
 *
 * - GIT_CHECKOUT_NOTIFY_UPDATED sends notification for any file changed.
 *
 * - GIT_CHECKOUT_NOTIFY_UNTRACKED notifies about untracked files.
 *
 * - GIT_CHECKOUT_NOTIFY_IGNORED notifies about ignored files.
 *
 * Returning a non-zero value from this callback will cancel the checkout.
 * Notification callbacks are made prior to modifying any files on disk.
 */
enum GitCheckoutNotify
{
    ///
    none = GIT_CHECKOUT_NOTIFY_NONE,

    ///
    conflict = GIT_CHECKOUT_NOTIFY_CONFLICT,

    ///
    dirty = GIT_CHECKOUT_NOTIFY_DIRTY,

    ///
    updated = GIT_CHECKOUT_NOTIFY_UPDATED,

    ///
    untracked = GIT_CHECKOUT_NOTIFY_UNTRACKED,

    ///
    notify_ignored = GIT_CHECKOUT_NOTIFY_IGNORED,

    ///
    notify_all = GIT_CHECKOUT_NOTIFY_ALL,
}

//~ /** Checkout notification callback function */
//~ alias git_checkout_notify_cb = int function(
        //~ git_checkout_notify_t why,
        //~ const(char)* path,
        //~ const(git_diff_file)* baseline,
        //~ const(git_diff_file)* target,
        //~ const(git_diff_file)* workdir,
        //~ void *payload);

//~ /** Checkout progress notification function */
//~ alias git_checkout_progress_cb = void function(
        //~ const(char)* path,
        //~ size_t completed_steps,
        //~ size_t total_steps,
        //~ void *payload);

/** Checkout options structure. */
struct GitCheckoutOptions
{
    uint version_ = git_checkout_opts.init.version_;

    GitCheckoutStrategy checkoutStrategy; /** default will be a dry run */

    int disableFilters;    /** don't apply filters like CRLF conversion */
    uint dirMode;  /** default is 0755 */
    uint fileMode; /** default is 0644 or 0755 as dictated by blob */
    int fileOpenFlags;    /** default is O_CREAT | O_TRUNC | O_WRONLY */

    uint notifyFlags; /** see `git_checkout_notify_t` above */
    git_checkout_notify_cb notifyCallback;
    void *notify_payload;

    /* Optional callback to notify the consumer of checkout progress. */
    git_checkout_progress_cb progressCallback;
    void *progress_payload;

    /** When not zeroed out, array of fnmatch patterns specifying which
     *  paths should be taken into account, otherwise all files.  Use
     *  GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH to treat as simple list.
     */
    git_strarray paths;

    git_tree* baseline; /** expected content of workdir, defaults to HEAD */

    string targetDir; /** alternative checkout path to workdir */
}

//~ enum GIT_CHECKOUT_OPTS_VERSION = 1;
//~ enum git_checkout_opts GIT_CHECKOUT_OPTS_INIT = { GIT_CHECKOUT_OPTS_VERSION };

//~ /**
 //~ * Updates files in the index and the working tree to match the content of
 //~ * the commit pointed at by HEAD.
 //~ *
 //~ * @param repo repository to check out (must be non-bare)
 //~ * @param opts specifies checkout options (may be NULL)
 //~ * @return 0 on success, GIT_EORPHANEDHEAD when HEAD points to a non existing
 //~ * branch, GIT_ERROR otherwise (use giterr_last for information
 //~ * about the error)
 //~ */
//~ int git_checkout_head(
        //~ git_repository *repo,
        //~ git_checkout_opts *opts);

//~ /**
 //~ * Updates files in the working tree to match the content of the index.
 //~ *
 //~ * @param repo repository into which to check out (must be non-bare)
 //~ * @param index index to be checked out (or NULL to use repository index)
 //~ * @param opts specifies checkout options (may be NULL)
 //~ * @return 0 on success, GIT_ERROR otherwise (use giterr_last for information
 //~ * about the error)
 //~ */
//~ int git_checkout_index(
        //~ git_repository *repo,
        //~ git_index *index,
        //~ git_checkout_opts *opts);

//~ /**
 //~ * Updates files in the index and working tree to match the content of the
 //~ * tree pointed at by the treeish.
 //~ *
 //~ * @param repo repository to check out (must be non-bare)
 //~ * @param treeish a commit, tag or tree which content will be used to update
 //~ * the working directory
 //~ * @param opts specifies checkout options (may be NULL)
 //~ * @return 0 on success, GIT_ERROR otherwise (use giterr_last for information
 //~ * about the error)
 //~ */
//~ int git_checkout_tree(
        //~ git_repository *repo,
        //~ const(git_object)* treeish,
        //~ git_checkout_opts *opts);
