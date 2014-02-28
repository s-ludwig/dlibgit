/*
 *              Copyright David Nadlinger 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.checkout;

// Note: This file includes none of the original comments, as they might
// be copyrightable material.

import git.object_;
import git.repository;
import git.tree;
import git.util;

import deimos.git2.checkout;
import deimos.git2.common;
import deimos.git2.diff;
import deimos.git2.strarray;
import deimos.git2.types;
import deimos.git2.util;

///
enum GitCheckoutStrategy
{
    ///
    none = GIT_CHECKOUT_NONE,

    ///
    safe = GIT_CHECKOUT_SAFE,

    ///
    safeCreate = GIT_CHECKOUT_SAFE_CREATE,

    ///
    force = GIT_CHECKOUT_FORCE,

    ///
    allowConflicts = GIT_CHECKOUT_ALLOW_CONFLICTS,

    ///
    removeUntracked = GIT_CHECKOUT_REMOVE_UNTRACKED,

    ///
    removeIgnored = GIT_CHECKOUT_REMOVE_IGNORED,

    ///
    updateOnly = GIT_CHECKOUT_UPDATE_ONLY,

    ///
    dontUpdateIndex = GIT_CHECKOUT_DONT_UPDATE_INDEX,

    ///
    noRefresh = GIT_CHECKOUT_NO_REFRESH,

    ///
    disablePathspecMatch = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH,

    ///
    skipLockedDirs = GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES,

    /// Not implemented yet!
    skipUnmerged = GIT_CHECKOUT_SKIP_UNMERGED,

    /// ditto
    useOurs = GIT_CHECKOUT_USE_OURS,

    /// ditto
    useTheirs = GIT_CHECKOUT_USE_THEIRS,

    /// ditto
    updateSubmods = GIT_CHECKOUT_UPDATE_SUBMODULES,

    /// ditto
    updateSubmodsIfChanged = GIT_CHECKOUT_UPDATE_SUBMODULES_IF_CHANGED,
}

///
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

alias GitCheckoutNotifyDelegate = void delegate(
    GitCheckoutNotify why,
    const(char)[] path,
    const(git_diff_file)* baseline,
    const(git_diff_file)* target,
    const(git_diff_file)* workdir);

extern(C) int cCheckoutNotifyCallback(
    git_checkout_notify_t why,
    const(char)* path,
    const(git_diff_file)* baseline,
    const(git_diff_file)* target,
    const(git_diff_file)* workdir,
    void *payload)
{
    auto dg = (cast(GitCheckoutOptions*)payload).notifyCallback;
    dg(cast(GitCheckoutNotify)why, toSlice(path), baseline, target, workdir);
    return 0; // TODO: What does this return value indicate?
}

alias GitCheckoutProgressDelegate = void delegate(
    const(char)[] path,
    size_t completed_steps,
    size_t total_steps
);

extern(C) void cCheckoutProgressCallback(
    const(char)* path,
    size_t completed_steps,
    size_t total_steps,
    void *payload)
{
    auto dg = (cast(GitCheckoutOptions*)payload).progressCallback;
    dg(toSlice(path), completed_steps, total_steps);
}

struct GitCheckoutOptions
{
    uint version_ = git_checkout_opts.init.version_;

    GitCheckoutStrategy strategy;

    int disableFilters;
    uint dirMode;
    uint fileMode;
    int fileOpenFlags;

    uint notifyFlags;

    GitCheckoutNotifyDelegate notifyCallback;
    GitCheckoutProgressDelegate progressCallback;

    git_strarray paths; // TODO: Translate.
    git_tree* baseline; // TODO: Translate.

    string targetDir;
}

package void toCCheckoutOpts(ref GitCheckoutOptions dOpts, ref git_checkout_opts cOpts)
{
    with (dOpts)
    {
        cOpts.version_ = version_;
        cOpts.checkout_strategy = cast(uint)strategy;
        cOpts.disable_filters = disableFilters;
        cOpts.dir_mode = fileMode;
        cOpts.file_mode = fileMode;
        cOpts.file_open_flags = fileOpenFlags;
        cOpts.notify_flags = notifyFlags;
        if (notifyCallback)
        {
            cOpts.notify_cb = &cCheckoutNotifyCallback;
            cOpts.notify_payload = cast(void*)&dOpts;
        }
        if (progressCallback)
        {
            cOpts.progress_cb = &cCheckoutProgressCallback;
            cOpts.progress_payload = cast(void*)&dOpts;
        }
        cOpts.paths = paths;
        cOpts.baseline = baseline;
        cOpts.target_directory = targetDir.gitStr;
    }
}

void checkoutHead(GitRepo repo, GitCheckoutOptions opts = GitCheckoutOptions.init)
{
    git_checkout_opts cOpts;
    opts.toCCheckoutOpts(cOpts);
    require(git_checkout_head(repo.cHandle, &cOpts) == 0);
}

void checkout(GitRepo repo, git_index* index, GitCheckoutOptions opts = GitCheckoutOptions.init) // TODO: Convert.
{
    git_checkout_opts cOpts;
    opts.toCCheckoutOpts(cOpts);
    require(git_checkout_index(repo.cHandle, index, &cOpts) == 0);
}

void checkout(GitRepo repo, GitObject treeish, GitCheckoutOptions opts = GitCheckoutOptions.init)
{
    git_checkout_opts cOpts;
    opts.toCCheckoutOpts(cOpts);
    require(git_checkout_tree(repo.cHandle, treeish.cHandle, &cOpts) == 0);
}

void checkout(GitRepo repo, GitTree treeish, GitCheckoutOptions opts = GitCheckoutOptions.init)
{
    git_checkout_opts cOpts;
    opts.toCCheckoutOpts(cOpts);
    require(git_checkout_tree(repo.cHandle, cast(git_object*)treeish.cHandle, &cOpts) == 0);
}
