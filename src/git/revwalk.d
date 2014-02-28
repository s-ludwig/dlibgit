/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.revwalk;

import git.commit;
import git.oid;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.errors;
import deimos.git2.revwalk;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;

// TODO: range interface?


GitRevWalk createRefWalk(GitRepo repo)
{
	git_revwalk* ret;
	require(git_revwalk_new(&ret, repo.cHandle) == 0);
	return GitRevWalk(repo, ret);
}

enum GitSortFlags {
	none = GIT_SORT_NONE,
	topological = GIT_SORT_TOPOLOGICAL,
	time = GIT_SORT_TIME,
	reverse = GIT_SORT_REVERSE
}

struct GitRevWalk {
	package this(GitRepo repo, git_revwalk* revwalk)
	{
		_repo = repo;
		_data = Data(revwalk);
	}

	@property void sortMode(GitSortFlags mode) { git_revwalk_sorting(this.cHandle, mode); }
	@property inout(GitRepo) repository() inout { return _repo; }

	void push(GitOid oid) { require(git_revwalk_push(this.cHandle, &oid._get_oid()) == 0); }
	void pushGlob(string glob) { require(git_revwalk_push_glob(this.cHandle, glob.toStringz) == 0); }
	void pushHead() { require(git_revwalk_push_head(this.cHandle) == 0); }
	void pushRef(string refname) { require(git_revwalk_push_ref(this.cHandle, refname.toStringz) == 0); }
	void pushRange(string range) { require(git_revwalk_push_range(this.cHandle, range.toStringz) == 0); }

	void hide(GitOid commit_id) { require(git_revwalk_hide(this.cHandle, &commit_id._get_oid()) == 0); }
	void hideGlob(string glob) { require(git_revwalk_hide_glob(this.cHandle, glob.toStringz) == 0); }
	void hideHead() { require(git_revwalk_hide_head(this.cHandle) == 0); }
	void hideRef(string refname) { require(git_revwalk_hide_ref(this.cHandle, refname.toStringz) == 0); }

	void reset() { git_revwalk_reset(this.cHandle); }

	static if (targetLibGitVersion >= VersionInfo(0, 20, 0))
		void simplifyFirstParent() { git_revwalk_simplify_first_parent(this.cHandle); }

	bool getNext(ref GitOid dst)
	{
		auto ret = git_revwalk_next(&dst._get_oid(), this.cHandle);
		if (ret == GIT_ITEROVER) return false;
		require(ret == 0);
		return true;
	}
	

	mixin RefCountedGitObject!(git_revwalk, git_revwalk_free);
	private GitRepo _repo;
}
