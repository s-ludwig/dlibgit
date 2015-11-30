/*
 *             Copyright Vladimir Panteleev 2015.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.merge;

import deimos.git2.merge;
import deimos.git2.types;

import git.index;
import git.repository;
import git.tree;
import git.util;

GitIndex mergeTrees(GitRepo repo, GitTree ancestor_tree, GitTree our_tree, GitTree their_tree, const git_merge_tree_opts* opts = null)
{
	git_index* index;
	require(git_merge_trees(&index, repo.cHandle(), ancestor_tree.cHandle(), our_tree.cHandle(), their_tree.cHandle(), opts) == 0);
	return GitIndex(repo, index);
}
