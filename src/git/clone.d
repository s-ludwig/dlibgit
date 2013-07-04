/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.clone;

import git.c.clone;

import git.checkout;
import git.repository;
import git.types;

/**
    Clone options structure.

    - `bare` should be set to zero to create a standard repo, non-zero for
    a bare repo

    - `fetch_progress_cb` is optional callback for fetch progress. Be aware that
    this is called inline with network and indexing operations, so performance
    may be affected.

    - `fetch_progress_payload` is payload for fetch_progress_cb

    ** "origin" remote options: **
    - `remote_name` is the name given to the "origin" remote.  The default is
    "origin".

    - `pushurl` is a URL to be used for pushing.  NULL means use the fetch url.

    - `fetch_spec` is the fetch specification to be used for fetching.  NULL
    results in the same behavior as GIT_REMOTE_DEFAULT_FETCH.

    - `push_spec` is the fetch specification to be used for pushing.  NULL means
    use the same spec as for fetching.

    - `cred_acquire_cb` is a callback to be used if credentials are required
    during the initial fetch.

    - `cred_acquire_payload` is the payload for the above callback.

    - `transport_flags` is flags used to create transport if no transport is
    provided.

    - `transport` is a custom transport to be used for the initial fetch.  NULL
    means use the transport autodetected from the URL.

    - `remote_callbacks` may be used to specify custom progress callbacks for
    the origin remote before the fetch is initiated.

    - `remote_autotag` may be used to specify the autotag setting before the
    initial fetch.  The default is GIT_REMOTE_DOWNLOAD_TAGS_ALL.

    - `checkout_branch` gives the name of the branch to checkout. NULL means
    use the remote's HEAD.
*/
struct GitCloneOptions
{
    uint version_ = git_clone_options.init.version_;

    /// options for the checkout step.  To disable checkout,
    /// set the `checkout_strategy` to GIT_CHECKOUT_DEFAULT.
    GitCheckoutOptions checkoutOptions;

    bool cloneBare;

    // todo: use toDelegate at the call site
    TransferCallbackDelegate transferCallback;

    string remoteName;
    string pushURL;
    string fetchSpec;
    string pushSpec;

    //~ GitCredAcquireCallback credAcquireCallback;
    //~ void* credPayload;

    //~ GitTransportFlags transportFlags;
    //~ GitTransport transport;
    //~ GitRemoteCallbacks[] remoteCallbacks;
    //~ GitRemoteAutotagOption autoTagOption;
    //~ string checkoutBranch;
}

/**
 * Clone a remote repository, and checkout the branch pointed to by the remote
 * HEAD.
 *
 * @param out pointer that will receive the resulting repository object
 * @param url the remote repository to clone
 * @param local_path local directory to clone to
 * @param options configuration options for the clone.  If NULL, the function
 * works as though GIT_OPTIONS_INIT were passed.
 * @return 0 on success, GIT_ERROR otherwise (use giterr_last for information
 * about the error)
 */
//~ GitRepo cloneRepo(in char[] url, in char[] localPath, GitCloneOptions options)
//~ {
    //~ git_repository* repo;
    //~ require(&repo, url.toStringz, localPath.toStringz, cast(git_clone_options*)&options);
    //~ return GitRepo(repo);
//~ }
