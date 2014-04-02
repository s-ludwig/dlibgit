/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.tag;

import git.commit;
import git.object_;
import git.oid;
import git.repository;
import git.signature;
import git.types;
import git.util;
import git.version_;

import deimos.git2.oid;
import deimos.git2.tag;
import deimos.git2.errors;
import deimos.git2.strarray;
import deimos.git2.types;

import std.conv : to;
import std.exception : enforce;
import std.string : toStringz;


GitTag lookupTag(GitRepo repo, GitOid oid)
{
	git_tag* dst;
	require(git_tag_lookup(&dst, repo.cHandle, &oid._get_oid()) == 0);
	return GitTag(repo, dst);
}

GitTag lookupTag(GitRepo repo, GitOid oid, size_t oid_length)
{
	git_tag* dst;
	require(git_tag_lookup_prefix(&dst, repo.cHandle, &oid._get_oid(), oid_length) == 0);
	return GitTag(repo, dst);
}

GitOid createTag(GitRepo repo, string tag_name, in GitObject target, in GitSignature tagger, string message, bool force)
{
	GitOid dst;
	require(git_tag_create(&dst._get_oid(), repo.cHandle, tag_name.toStringz, target.cHandle, tagger.cHandle, message.toStringz(), force) == 0);
	return dst;
}

GitOid createTagAnnotation(GitRepo repo, string tag_name, in GitObject target, in GitSignature tagger, string message)
{
	GitOid dst;
	require(git_tag_annotation_create(&dst._get_oid(), repo.cHandle, tag_name.toStringz, target.cHandle, tagger.cHandle, message.toStringz()) == 0);
	return dst;
}

GitOid createTagFromBuffer(GitRepo repo, string buffer, bool force)
{
	GitOid dst;
	require(git_tag_create_frombuffer(&dst._get_oid(), repo.cHandle, buffer.toStringz, force) == 0);
	return dst;
}

GitOid createTagLightweight(GitRepo repo, string tag_name, in GitObject target, bool force)
{
	GitOid dst;
	require(git_tag_create_lightweight(&dst._get_oid(), repo.cHandle, tag_name.toStringz, target.cHandle, force) == 0);
	return dst;
}

void deleteTag(GitRepo repo, string tag_name)
{
	require(git_tag_delete(repo.cHandle, tag_name.toStringz) == 0);
}

void iterateTags(GitRepo repo, scope ContinueWalk delegate(string name, GitOid oid) del)
{
	static struct CTX { ContinueWalk delegate(string name, GitOid oid) del; Exception e; }

	static extern(C) nothrow int callback(const(char)* name, git_oid *oid, void *payload)
	{
		auto ctx = cast(CTX*)payload;
		try {
			if (ctx.del(name.to!string, GitOid(*oid)) != ContinueWalk.yes)
				return 1;
		} catch (Exception e) {
			ctx.e = e;
			return -1;
		}
		return 0;
	}

	auto ctx = CTX(del);
	auto ret = git_tag_foreach(repo.cHandle, &callback, &ctx);
	if (ctx.e) throw ctx.e;
	require(ret == 0);
}

string[] listTags(GitRepo repo)
{
	git_strarray arr;
	require(git_tag_list(&arr, repo.cHandle) == 0);
	git_strarray_free(&arr);
	auto ret = new string[arr.count];
	foreach (i; 0 .. arr.count)
		ret[i] = arr.strings[i].to!string;
	return ret;
}

string[] listMatchingTags(GitRepo repo, string pattern)
{
	git_strarray arr;
	require(git_tag_list_match(&arr, pattern.toStringz, repo.cHandle) == 0);
	git_strarray_free(&arr);
	auto ret = new string[arr.count];
	foreach (i; 0 .. arr.count)
		ret[i] = arr.strings[i].to!string;
	return ret;
}


struct GitTag {
	this(GitObject obj)
	{
		enforce(obj.type == GitType.tag, "GIT object is not a tag.");
		_object = obj;
	}

	package this(GitRepo repo, git_tag* tag)
	{
		_object = GitObject(repo, cast(git_object*)tag);
	}

	@property inout(GitRepo) owner() inout { return _object.owner; }
	@property GitOid id() const { return GitOid(*git_tag_id(this.cHandle)); }
	@property string name() { return git_tag_name(this.cHandle).to!string; }
	@property GitObject target()
	{
		git_object* dst;
		require(git_tag_target(&dst, this.cHandle) == 0);
		return GitObject(this.owner, dst);
	}
	@property GitOid targetID() const { return GitOid(*git_tag_target_id(this.cHandle)); }
	@property GitType targetType() const { return cast(GitType)git_tag_target_type(this.cHandle); }
	@property GitSignature tagger() { return GitSignature(this, git_tag_tagger(this.cHandle)); }
	@property string message() const { return git_tag_message(this.cHandle).to!string; }

	GitObject peel()
	{
		git_object* dst;
		require(git_tag_peel(&dst, this.cHandle) == 0);
		return GitObject(this.owner, dst);
	}

	package @property inout(git_tag)* cHandle() inout { return cast(inout(git_tag)*)_object.cHandle; }

	private GitObject _object;
}
