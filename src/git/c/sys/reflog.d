module git.c.sys.reflog;

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import git.c.common;
import git.c.types;
import git.c.oid;

git_reflog_entry* git_reflog_entry__alloc();
void git_reflog_entry__free(git_reflog_entry *entry);
