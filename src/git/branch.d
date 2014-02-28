/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.branch;

import git.commit;
import git.oid;
import git.reference;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.branch;
import deimos.git2.errors;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;

GitBranch createBranch(GitRepo repo, string name, GitCommit target, bool force)
{
	git_reference* ret;
	require(git_branch_create(&ret, repo.cHandle, name.toStringz, target.cHandle, force) == 0);
	return GitBranch(GitReference(repo, ret));
}

GitBranch lookupBranch(GitRepo repo, string name, GitBranchType type)
{
	git_reference* ret;
	require(git_branch_lookup(&ret, repo.cHandle, name.toStringz(), cast(git_branch_t)type) == 0);
	return GitBranch(GitReference(repo, ret));
}

void deleteBranch(GitBranch branch)
{
	require(git_branch_delete(branch.cHandle) == 0);
}

void iterateBranches(GitRepo repo, GitBranchType types, scope BranchIterationDelegate del)
{
	static if (targetLibGitVersion == VersionInfo(0, 19, 0)) {
		static struct CTX { BranchIterationDelegate del; GitRepo repo; Exception e; }
		static extern(C) nothrow int callback(const(char)* name, git_branch_t type, void* payload) {
			auto ctx = cast(CTX*)payload;
			try {
				auto gtp = cast(GitBranchType)type;
				if (ctx.del(lookupBranch(ctx.repo, name.to!string, gtp), gtp) == ContinueWalk.no)
					return 1;
			} catch (Exception e) {
				ctx.e = e;
				return -1;
			}
			return 0;
		}

		auto ctx = CTX(del, repo);
		auto ret = git_branch_foreach(repo.cHandle, cast(git_branch_t)types, &callback, &ctx);
		if (ret == GIT_EUSER) {
			if (ctx.e) throw ctx.e;
			else return;
		}
		require(ret == 0);
	} else {
		git_branch_iterator* it;
		require(git_branch_iterator_new(&it, repo.cHandle, cast(git_branch_t)types) == 0);
		scope (exit) git_branch_iterator_free(it);
		while (true) {
			git_reference* br;
			git_branch_t brtp;
			auto ret = git_branch_next(&br, &brtp, it);
			if (ret == GIT_ITEROVER) break;
			require(ret == 0);
			if (del(GitBranch(GitReference(repo, br)), cast(GitBranchType)brtp) == ContinueWalk.no)
				break;
		}
	}
}

enum GitBranchType {
	local = GIT_BRANCH_LOCAL,
	remote = GIT_BRANCH_REMOTE
}

alias BranchIterationDelegate = ContinueWalk delegate(GitBranch branch, GitBranchType type);

struct GitBranch {
	protected this(GitReference ref_)
	{
		_ref = ref_;
	}

	@property inout(GitReference) reference() inout { return _ref; }

	@property string name()
	{
		const(char)* ret;
		require(git_branch_name(&ret, this.cHandle) == 0);
		return ret.to!string();
	}

	@property GitBranch upstream()
	{
		git_reference* ret;
		require(git_branch_upstream(&ret, this.cHandle) == 0);
		return GitBranch(GitReference(_ref.owner, ret));
	}

	@property string upstreamName()
	{
		const(char)* branch_name;
		require(git_branch_name(&branch_name, this.cHandle) == 0);
		auto len = git_branch_upstream_name(null, 0, _ref.owner.cHandle, branch_name);
		require(len > 0);
		auto dst = new char[len];
		require(git_branch_upstream_name(dst.ptr, dst.length, _ref.owner.cHandle, branch_name) == len);
		return cast(immutable)dst[0 .. $-1]; // skip trailing 0
	}

	@property void upstreamName(string name)
	{
		require(git_branch_set_upstream(_ref.cHandle, name.toStringz()) == 0);
	}

	@property bool isHead() { return requireBool(git_branch_is_head(_ref.cHandle)); }

	@property string remoteName()
	{
		const(char)* branch_name;
		require(git_branch_name(&branch_name, this.cHandle) == 0);
		auto len = git_branch_remote_name(null, 0, _ref.owner.cHandle, branch_name);
		require(len > 0);
		auto dst = new char[len];
		require(git_branch_remote_name(dst.ptr, dst.length, _ref.owner.cHandle, branch_name) == len);
		return cast(immutable)dst[0 .. $-1]; // skip trailing 0
	}

	GitBranch move(string new_name, bool force)
	{
		git_reference* dst;
		require(git_branch_move(&dst, _ref.cHandle, new_name.toStringz(), force) == 0);
		return GitBranch(GitReference(_ref.owner, dst));
	}

	alias reference this;

	package inout(git_reference)* cHandle() inout { return _ref.cHandle; }
private:
	GitReference _ref;
}
