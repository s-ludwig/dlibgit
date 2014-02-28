/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.reference;

import git.object_;
import git.oid;
import git.repository;
import git.types;
import git.util;

import deimos.git2.refs;
import deimos.git2.types;

import std.conv : to;
import std.exception : enforce;
import std.string : toStringz;


GitReference lookupReference(GitRepo repo, string name)
{
	git_reference* ret;
	require(git_reference_lookup(&ret, repo.cHandle, name.toStringz()) == 0);
	return GitReference(repo, ret);
}

GitOid lookupReferenceId(GitRepo repo, string name)
{
	GitOid ret;
	require(git_reference_name_to_id(&ret._get_oid(), repo.cHandle, name.toStringz()) == 0);
	return ret;
}

GitReference dwimReference(GitRepo repo, string shorthand)
{
	git_reference* ret;
	require(git_reference_dwim(&ret,repo.cHandle, shorthand.toStringz()) == 0);
	return GitReference(repo, ret);
}

GitReference createSymbolicReference(GitRepo repo, string name, string target, bool force)
{
	git_reference* ret;
	require(git_reference_symbolic_create(&ret, repo.cHandle, name.toStringz(), target.toStringz(), force) == 0);
	return GitReference(repo, ret);
}

GitReference createReference(GitRepo repo, string name, GitOid target, bool force)
{
	git_reference* ret;
	require(git_reference_create(&ret, repo.cHandle, name.toStringz(), &target._get_oid(), force) == 0);
	return GitReference(repo, ret);
}


struct GitReference {
	this(GitObject object)
	{
		enforce(object.type == GitType.commit, "GIT object is not a reference.");
		_object = object;
	}

	package this(GitRepo repo, git_reference* reference)
	{
		_object = GitObject(repo, cast(git_object*)reference);
	}

	@property GitOid target() { return GitOid(*git_reference_target(this.cHandle)); }
	@property GitOid peeledTarget() { return GitOid(*git_reference_target_peel(this.cHandle)); }
	@property string symbolicTarget() { return git_reference_symbolic_target(this.cHandle).to!string; }
	@property git_ref_t type() { return git_reference_type(this.cHandle); }
	@property string name() { return git_reference_name(this.cHandle).to!string; }
	@property GitRepo owner() { return _object.owner; }

	GitReference resolve()
	{
		git_reference* ret;
		require(git_reference_resolve(&ret, this.cHandle) == 0);
		return GitReference(this.owner, ret);
	}

	GitReference setSymbolicTarget(string target)
	{
		git_reference* ret;
		require(git_reference_symbolic_set_target(&ret, this.cHandle, target.toStringz) == 0);
		return GitReference(this.owner, ret);
	}

	GitReference setTarget(GitOid oid)
	{
		git_reference* ret;
		require(git_reference_set_target(&ret, this.cHandle, &oid._get_oid()) == 0);
		return GitReference(this.owner, ret);
	}

	GitReference rename(string new_name, bool force)
	{
		git_reference* ret;
		require(git_reference_rename(&ret, this.cHandle, new_name.toStringz, force) == 0);
		return GitReference(this.owner, ret);
	}

	void delete_() { require(git_reference_delete(this.cHandle) == 0); }


/*int git_reference_list(git_strarray *array, git_repository *repo);

alias git_reference_foreach_cb = int function(git_reference *reference, void *payload);
alias git_reference_foreach_name_cb = int function(const(char)* name, void *payload);

int git_reference_foreach(
	git_repository *repo,
	git_reference_foreach_cb callback,
	void *payload);
int git_reference_foreach_name(
	git_repository *repo,
	git_reference_foreach_name_cb callback,
	void *payload);
void git_reference_free(git_reference *ref_);
int git_reference_cmp(git_reference *ref1, git_reference *ref2);
int git_reference_iterator_new(
	git_reference_iterator **out_,
	git_repository *repo);
int git_reference_iterator_glob_new(
	git_reference_iterator **out_,
	git_repository *repo,
	const(char)* glob);
int git_reference_next(git_reference **out_, git_reference_iterator *iter);
int git_reference_next_name(const(char)** out_, git_reference_iterator *iter);
void git_reference_iterator_free(git_reference_iterator *iter);
int git_reference_foreach_glob(
	git_repository *repo,
	const(char)* glob,
	git_reference_foreach_name_cb callback,
	void *payload);
int git_reference_has_log(git_reference *ref_);
int git_reference_is_branch(git_reference *ref_);
int git_reference_is_remote(git_reference *ref_);
int git_reference_is_tag(git_reference *ref_);

enum git_reference_normalize_t {
	GIT_REF_FORMAT_NORMAL = 0u,
	GIT_REF_FORMAT_ALLOW_ONELEVEL = (1u << 0),
	GIT_REF_FORMAT_REFSPEC_PATTERN = (1u << 1),
	GIT_REF_FORMAT_REFSPEC_SHORTHAND = (1u << 2),
}
mixin _ExportEnumMembers!git_reference_normalize_t;

int git_reference_normalize_name(
	char *buffer_out,
	size_t buffer_size,
	const(char)* name,
	uint flags);
int git_reference_peel(
	git_object **out_,
	git_reference *ref_,
	git_otype type);
int git_reference_is_valid_name(const(char)* refname);
const(char)*  git_reference_shorthand(git_reference *ref_);*/

	package @property inout(git_reference)* cHandle() inout { return cast(inout(git_reference)*)_object.cHandle; } 

	private GitObject _object;
}
