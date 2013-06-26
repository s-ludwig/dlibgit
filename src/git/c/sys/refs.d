module git.c.sys.refs;

extern (C):

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.types;
import git.c.oid;

/**
 * Create a new direct reference from an OID.
 *
 * @param name the reference name
 * @param oid the object id for a direct reference
 * @param symbolic the target for a symbolic reference
 * @return the created git_reference or NULL on error
 */
git_reference * git_reference__alloc(
	const(char)* name,
	const(git_oid)* oid,
	const(git_oid)* peel);

/**
 * Create a new symbolic reference.
 *
 * @param name the reference name
 * @param symbolic the target for a symbolic reference
 * @return the created git_reference or NULL on error
 */
git_reference * git_reference__alloc_symbolic(
	const(char)* name,
	const(char)* target);

//#endif
