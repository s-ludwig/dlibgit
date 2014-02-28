/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.commit;

import git.oid;
import git.repository;
import git.signature;
import git.tree;
import git.types;
import git.util;
import git.version_;

import deimos.git2.commit;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;


GitCommit lookupCommit(GitRepo repo, GitOid oid)
{
	git_commit* ret;
	require(git_commit_lookup(&ret, repo.cHandle, &oid._get_oid()) == 0);
	return GitCommit(repo, ret);
}

GitCommit lookupCommitPrefix(GitRepo repo, GitOid oid, size_t oid_length)
{
	git_commit* ret;
	require(git_commit_lookup_prefix(&ret, repo.cHandle, &oid._get_oid(), oid_length) == 0);
	return GitCommit(repo, ret);
}

GitOid createCommit(GitRepo repo, string update_ref, GitSignature author, GitSignature committer, string message, GitTree tree, const(GitCommit)[] parents)
{
	GitOid ret;
	assert(parents.length < int.max, "Number of parents may not exceed int.max");
	auto cparents = new const(git_commit)*[parents.length];
	foreach (i, ref cp; cparents) cp = parents[i].cHandle;
	require(git_commit_create(&ret._get_oid(), repo.cHandle,
		update_ref ? update_ref.toStringz : null, author.cHandle, committer.cHandle,
		null, message.toStringz, tree.cHandle, cast(int)cparents.length, cparents.ptr) == 0);
	return ret;
}


struct GitCommit {
	package this(GitRepo repo, git_commit* commit)
	{
		_repo = repo;
		_data = Data(commit);
	}

	@property GitOid id() { return GitOid(*git_commit_id(this.cHandle)); }
	@property GitRepo owner() { return _repo; }
	@property string messageEncoding() { return git_commit_message_encoding(this.cHandle).to!string; }
	@property string message() { return git_commit_message(this.cHandle).to!string; }
	static if (targetLibGitVersion >= VersionInfo(0, 20, 0))
		@property string rawMessage() { return git_commit_message_raw(this.cHandle).to!string; }

	// TODO: use SysTime instead
	@property git_time_t commitTime() { return git_commit_time(this.cHandle); }
	@property int commitTimeOffset() { return git_commit_time_offset(this.cHandle); }

	@property GitSignature committer() { return GitSignature(this, git_commit_committer(this.cHandle)); }
	@property GitSignature author() { return GitSignature(this, git_commit_author(this.cHandle)); }
	static if (targetLibGitVersion >= VersionInfo(0, 20, 0))
		@property string rawHeader() { return git_commit_raw_header(this.cHandle).to!string; }

	@property GitTree tree()
	{
		git_tree* ret;
		require(git_commit_tree(&ret, this.cHandle) == 0);
		return GitTree(_repo, ret);
	}
	@property GitOid treeId() { return GitOid(*git_commit_tree_id(this.cHandle)); }

	@property uint parentCount() { return git_commit_parentcount(this.cHandle); }

	GitCommit getParent(uint index)
	{
		git_commit* ret;
		require(git_commit_parent(&ret, this.cHandle, index) == 0);
		return GitCommit(_repo, ret);
	}

	GitOid getParentOid(uint index)
	{
		return GitOid(*git_commit_parent_id(this.cHandle, index));
	}

	GitCommit getNthGenAncestor(uint n)
	{
		git_commit* ret;
		require(git_commit_nth_gen_ancestor(&ret, this.cHandle, n) == 0);
		return GitCommit(_repo, ret);
	}

	package inout(git_commit)* cHandle() inout { return _data._payload; }

private:
	struct Payload
	{
		this(git_commit* payload)
		{
			_payload = payload;
		}

		~this()
		{
			if (_payload !is null)
			{
				git_commit_free(_payload);
				_payload = null;
			}
		}

		/// Should never perform copy
		@disable this(this);

		/// Should never perform assign
		@disable void opAssign(typeof(this));

		git_commit* _payload;
	}

	// Reference to the parent repository to keep it alive.
	GitRepo _repo;

	import std.typecons : RefCounted, RefCountedAutoInitialize;
	alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
	Data _data;
}