module git.c.net;

extern (C):

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.oid;
import git.c.types;

/**
 * @file git2/net.h
 * @brief Git networking declarations
 * @ingroup Git
 * @{
 */


enum GIT_DEFAULT_PORT = "9418";

/*
 * We need this because we need to know whether we should call
 * git-upload-pack or git-receive-pack on the remote end when get_refs
 * gets called.
 */

enum git_direction {
	GIT_DIRECTION_FETCH = 0,
	GIT_DIRECTION_PUSH  = 1
} ;


/**
 * Remote head description, given out on `ls` calls.
 */
struct git_remote_head {
	int local; /* available locally */
	git_oid oid;
	git_oid loid;
	char *name;
}

/**
 * Callback for listing the remote heads
 */
alias git_headlist_cb = int function(git_remote_head *rhead, void *payload);
