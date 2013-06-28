module git.c.message;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

/**
 * @file git2/message.h
 * @brief Git message management routines
 * @ingroup Git
 * @{
 */

import git.c.common;

extern (C):

/**
 * Clean up message from excess whitespace and make sure that the last line
 * ends with a '\n'.
 *
 * Optionally, can remove lines starting with a "#".
 *
 * @param out The user-allocated buffer which will be filled with the
 *     cleaned up message. Pass NULL if you just want to get the needed
 *     size of the prettified message as the output value.
 *
 * @param out_size Size of the `out` buffer in bytes.
 *
 * @param message The message to be prettified.
 *
 * @param strip_comments Non-zero to remove lines starting with "#", 0 to
 *     leave them in.
 *
 * @return -1 on error, else number of characters in prettified message
 *     including the trailing NUL byte
 */
int git_message_prettify(
	char *out_,
	size_t out_size,
	const(char)* message,
	int strip_comments);




 /* INCLUDE_git_message_h__ */

