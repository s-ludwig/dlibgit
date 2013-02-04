module git2.clone;

import git2.checkout;
import git2.indexer;
import git2.remote;
import git2.transport;
import git2.types;

extern(C):

struct git_clone_options {
	uint version_ = GIT_CLONE_OPTIONS_VERSION;

	git_checkout_opts checkout_opts;
	int bare;
	git_transfer_progress_callback fetch_progress_cb;
	void* fetch_progress_payload;

	const(char)* remote_name;
	const(char)* pushurl;
	const(char)* fetch_spec;
	const(char)* push_spec;
	git_cred_acquire_cb cred_acquire_cb;
	void* cred_acquire_payload;
	git_transport* transport;
	git_remote_callbacks* remote_callbacks;
	git_remote_autotag_option remote_autotag;
	const(char)* checkout_branch;
}

enum GIT_CLONE_OPTIONS_VERSION = 1;

int git_clone(git_repository** out_, const(char)* url, const(char)* local_path, const(git_clone_options)* options);
