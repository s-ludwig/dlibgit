/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.revparse;

import git.commit;
import git.object_;
import git.oid;
import git.reference;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.revparse;
import deimos.git2.errors;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;
import std.typecons : Tuple, tuple;


GitObject revparseSingle(GitRepo repo, string spec)
{
	git_object* ret;
	require(git_revparse_single(&ret, repo.cHandle, spec.toStringz) == 0);
	return GitObject(repo, ret);
}

Tuple!(GitObject, GitReference) revparseExt(GitRepo repo, string spec)
{
	git_object* obj;
	git_reference* ref_;
	require(git_revparse_ext(&obj, &ref_, repo.cHandle, spec.toStringz) == 0);
	return tuple(GitObject(repo, obj), GitReference(repo, ref_));
}

GitRevSpec revparse(GitRepo repo, string spec)
{
	git_revspec dst;
	require(git_revparse(&dst, repo.cHandle, spec.toStringz) == 0);
	return GitRevSpec(repo, dst);
}

struct GitRevSpec {
	package this(GitRepo repo, git_revspec spec)
	{
		from = GitObject(repo, spec.from);
		to = GitObject(repo, spec.to);
		flags = cast(GitRevparseModeFlags)spec.flags;
	}

	GitObject from;
	GitObject to;
	GitRevparseModeFlags flags;
}

enum GitRevparseModeFlags {
	single = GIT_REVPARSE_SINGLE,
	range = GIT_REVPARSE_RANGE,
	mergeBase = GIT_REVPARSE_MERGE_BASE
}
