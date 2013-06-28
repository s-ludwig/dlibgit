module git.c.threads;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/threads.h
 * @brief Library level thread functions
 * @defgroup git_thread Threading functions
 * @ingroup Git
 * @{
 */

import git.c.common;

extern (C):

/**
 * Init the threading system.
 *
 * If libgit2 has been built with GIT_THREADS
 * on, this function must be called once before
 * any other library functions.
 *
 * If libgit2 has been built without GIT_THREADS
 * support, this function is a no-op.
 *
 * @return 0 or an error code
 */
int git_threads_init();

/**
 * Shutdown the threading system.
 *
 * If libgit2 has been built with GIT_THREADS
 * on, this function must be called before shutting
 * down the library.
 *
 * If libgit2 has been built without GIT_THREADS
 * support, this function is a no-op.
 */
void git_threads_shutdown();





