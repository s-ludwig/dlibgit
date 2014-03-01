/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.blob;

import git.commit;
import git.object_;
import git.oid;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.blob;
import deimos.git2.errors;
import deimos.git2.types;

import std.conv : to;
import std.exception : enforce;
import std.string : toStringz;


GitBlob lookupBlob(GitRepo repo, GitOid oid)
{
	git_blob* ret;
	require(git_blob_lookup(&ret, repo.cHandle, &oid._get_oid()) == 0);
	return GitBlob(repo, ret);
}

GitBlob lookupBlobPrefix(GitRepo repo, GitOid oid, size_t oid_length)
{
	git_blob* ret;
	require(git_blob_lookup_prefix(&ret, repo.cHandle, &oid._get_oid(), oid_length) == 0);
	return GitBlob(repo, ret);
}

GitOid createBlob(GitRepo repo, in ubyte[] buffer)
{
	GitOid ret;
	require(git_blob_create_frombuffer(&ret._get_oid(), repo.cHandle, buffer.ptr, buffer.length) == 0);
	return ret;
}

/*GitOid createBlob(R)(GitRepo repo, R input_range)
	if (isInputRange!R)
{
	alias git_blob_chunk_cb = int function(char *content, size_t max_length, void *payload);
		int git_blob_create_fromchunks(
		git_oid *id,
		git_repository *repo,
		const(char)* hintpath,
		git_blob_chunk_cb callback,
		void *payload);

}*/

GitOid createBlobFromWorkDir(GitRepo repo, string relative_path)
{
	GitOid ret;
	require(git_blob_create_fromworkdir(&ret._get_oid(), repo.cHandle, relative_path.toStringz()) == 0);
	return ret;
}

GitOid createBlobFromDisk(GitRepo repo, string path)
{
	GitOid ret;
	require(git_blob_create_fromdisk(&ret._get_oid(), repo.cHandle, path.toStringz()) == 0);
	return ret;
}


struct GitBlob {
	this(GitObject object)
	{
		enforce(object.type == GitType.blob, "GIT object is not a blob.");
		_object = object;
	}

	package this(GitRepo repo, git_blob* blob)
	{
		_object = GitObject(repo, cast(git_object*)blob);
	}

	@property GitRepo owner() { return _object.owner; }
	@property GitOid id() { return GitOid(*git_blob_id(this.cHandle)); }

	@property const(ubyte)[] rawContent()
	{
		auto ptr = git_blob_rawcontent(this.cHandle);
		auto length = git_blob_rawsize(this.cHandle);
		enforce(length <= size_t.max, "Blob too large to fit in memory.");
		return cast(const(ubyte)[])ptr[0 .. cast(size_t)length];
	}

	@property bool isBinary() { return requireBool(git_blob_is_binary(this.cHandle)); }

	/*ubyte[] getFilteredContent()
	{
		int git_blob_filtered_content(git_buf *out_, git_blob *blob, const(char)* as_path, int check_for_binary_data);
	}*/

	package @property inout(git_blob)* cHandle() inout { return cast(inout(git_blob)*)_object.cHandle; }

	private GitObject _object;
}
