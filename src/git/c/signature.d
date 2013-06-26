module git.c.signature;

extern (C):

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.types;

/**
 * @file git2/signature.h
 * @brief Git signature creation
 * @defgroup git_signature Git signature creation
 * @ingroup Git
 * @{
 */


/**
 * Create a new action signature.
 *
 * Call `git_signature_free()` to free the data.
 *
 * Note: angle brackets ('<' and '>') characters are not allowed
 * to be used in either the `name` or the `email` parameter.
 *
 * @param out new signature, in case of error NULL
 * @param name name of the person
 * @param email email of the person
 * @param time time when the action happened
 * @param offset timezone offset in minutes for the time
 * @return 0 or an error code
 */
int git_signature_new(git_signature **out_, const(char)* name, const(char)* email, git_time_t time, int offset);

/**
 * Create a new action signature with a timestamp of 'now'.
 *
 * Call `git_signature_free()` to free the data.
 *
 * @param out new signature, in case of error NULL
 * @param name name of the person
 * @param email email of the person
 * @return 0 or an error code
 */
int git_signature_now(git_signature **out_, const(char)* name, const(char)* email);


/**
 * Create a copy of an existing signature.  All internal strings are also
 * duplicated.
 *
 * Call `git_signature_free()` to free the data.
 *
 * @param sig signature to duplicated
 * @return a copy of sig, NULL on out of memory
 */
git_signature * git_signature_dup(const(git_signature)* sig);

/**
 * Free an existing signature.
 *
 * Because the signature is not an opaque structure, it is legal to free it
 * manually, but be sure to free the "name" and "email" strings in addition
 * to the structure itself.
 *
 * @param sig signature to free
 */
void git_signature_free(git_signature *sig);




