module git.c.graph;

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
 * @file git2/graph.h
 * @brief Git graph traversal routines
 * @defgroup git_revwalk Git graph traversal routines
 * @ingroup Git
 * @{
 */


/**
 * Count the number of unique commits between two commit objects
 *
 * There is no need for branches containing the commits to have any
 * upstream relationship, but it helps to think of one as a branch and
 * the other as its upstream, the `ahead` and `behind` values will be
 * what git would report for the branches.
 *
 * @param ahead number of unique from commits in `upstream`
 * @param behind number of unique from commits in `local`
 * @param repo the repository where the commits exist
 * @param local the commit for local
 * @param upstream the commit for upstream
 */
int git_graph_ahead_behind(size_t *ahead, size_t *behind, git_repository *repo, const(git_oid)* local, const(git_oid)* upstream);





