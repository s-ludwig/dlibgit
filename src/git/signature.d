/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.signature;

import git.commit;
import git.oid;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.signature;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;

static if (targetLibGitVersion >= VersionInfo(0, 20, 0)) {
	GitSignature createDefaultSignature(GitRepo repo)
	{
		git_signature* ret;
		require(git_signature_default(&ret, repo.cHandle) == 0);
		return GitSignature(ret);
	}
}

/*GitSignature createSignature(string name, string email, SysTime time)
{
	git_signature* ret;
	require(git_signature_new(&ret, name.toStringz, email.toStringz, gtime, gofffset) == 0);
	return GitSignature(ret);
}*/

GitSignature createSignature(string name, string email)
{
	git_signature* ret;
	require(git_signature_now(&ret, name.toStringz, email.toStringz) == 0);
	return GitSignature(ret);
}

struct GitSignature {
	package this(git_signature* sig)
	{
		_commit = GitCommit.init;
		_data = Data(sig);
	}

	package this(GitCommit owner, const(git_signature)* sig)
	{
		_commit = owner;
		_sig = sig;
	}

	@property GitSignature dup() { return GitSignature(git_signature_dup(this.cHandle)); }

	package const(git_signature)* cHandle() const { return _sig ? _sig : _data._payload; }

	mixin RefCountedGitObject!(git_signature, git_signature_free, false);

private:
	// Reference to the parent commit to keep it alive.
	GitCommit _commit;
	const(git_signature)* _sig;
}
