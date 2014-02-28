/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.submodule;

import git.commit;
import git.oid;
import git.tree;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.submodule;
import deimos.git2.errors;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;

GitSubModule lookupSubmodule(GitRepo repo, string name)
{
	git_submodule* dst;
	require(git_submodule_lookup(&dst, repo.cHandle, name.toStringz) == 0);
	return GitSubModule(repo, dst);
}

GitSubModule addSubModuleAndSetup(GitRepo repo, string url, string path, bool use_gitlink)
{
	git_submodule* dst;
	require(git_submodule_add_setup(&dst, repo.cHandle, url.toStringz, path.toStringz, use_gitlink) == 0);
	return GitSubModule(repo, dst);
}

void iterateSubModules(GitRepo repo, scope ContinueWalk delegate(GitSubModule dm, string name) del)
{
	struct CTX { ContinueWalk delegate(GitSubModule dm, string name) del; GitRepo repo; Exception e; }

	static extern(C) nothrow int callback(git_submodule* sm, const(char)* name, void* payload)
	{
		auto ctx = cast(CTX*)payload;
		try {
			if (ctx.del(GitSubModule(ctx.repo, sm), name.to!string) != ContinueWalk.yes)
				return 1;
		} catch (Exception e) {
			ctx.e = e;
			return -1;
		}
		return 0;
	}

	auto ctx = CTX(del, repo);
	auto ret = git_submodule_foreach(repo.cHandle, &callback, &ctx);
	if (ctx.e) throw ctx.e;
	require(ret == 0);
}

void reloadSubModules(GitRepo repo)
{
	require(git_submodule_reload_all(repo.cHandle) == 0);
}

struct GitSubModule {
	package this(GitRepo repo, git_submodule* submod)
	{
		_repo = repo;
		_submod = submod;
	}

	@property inout(GitRepo) owner() inout { return _repo; }

	@property string name() { return git_submodule_name(this.cHandle).to!string; }
	@property string path() { return git_submodule_path(this.cHandle).to!string; }
	@property string url() { return git_submodule_url(this.cHandle).to!string; }
	@property void url(string url) { require(git_submodule_set_url(this.cHandle, url.toStringz) == 0); }
	@property GitOid indexID() { return GitOid(*git_submodule_index_id(this.cHandle)); }
	@property GitOid headID() { return GitOid(*git_submodule_head_id(this.cHandle)); }
	@property GitOid wdID() { return GitOid(*git_submodule_wd_id(this.cHandle)); }
	/*@property git_submodule_ignore_t git_submodule_ignore(
	this.cHandle);
git_submodule_ignore_t git_submodule_set_ignore(
	this.cHandle,
	git_submodule_ignore_t ignore);
git_submodule_update_t git_submodule_update(
	this.cHandle);
git_submodule_update_t git_submodule_set_update(
	this.cHandle,
	git_submodule_update_t update);*/
	@property bool fetchRecurseSubModules() { return git_submodule_fetch_recurse_submodules(this.cHandle) != 0; }
	@property void fetchRecurseSubModules(bool value) { require(git_submodule_set_fetch_recurse_submodules(this.cHandle, value) == 0); }

	@property GitSubModuleStatusFlags status()
	{
		uint dst;
		require(git_submodule_status(&dst, this.cHandle) == 0);
		return cast(GitSubModuleStatusFlags)dst;
	}

	@property GitSubModuleStatusFlags location()
	{
		uint dst;
		require(git_submodule_location(&dst, this.cHandle) == 0);
		return cast(GitSubModuleStatusFlags)dst;
	}

	GitRepo open()
	{
		git_repository* dst;
		require(git_submodule_open(&dst, this.cHandle) == 0);
		return GitRepo(dst);
	}

	void init(bool overwrite) { require(git_submodule_init(this.cHandle, overwrite) == 0); }
	void save() { require(git_submodule_save(this.cHandle) == 0); }
	void sync() { require(git_submodule_sync(this.cHandle) == 0); }
	void reload() { require(git_submodule_reload(this.cHandle) == 0); }

	void finalizeAdd() { require(git_submodule_add_finalize(this.cHandle) == 0); }

	void addToIndex(bool write_index) { require(git_submodule_add_to_index(this.cHandle, write_index) == 0); }


	package @property inout(git_submodule)* cHandle() inout { return _submod; }

	private git_submodule* _submod;
	// Reference to the parent repository to keep it alive.
	private GitRepo _repo;
}


enum GitSubModuleStatusFlags {
	inHead = GIT_SUBMODULE_STATUS_IN_HEAD,
	inIndex = GIT_SUBMODULE_STATUS_IN_INDEX,
	inConfig = GIT_SUBMODULE_STATUS_IN_CONFIG,
	inWD = GIT_SUBMODULE_STATUS_IN_WD,
	indexAdded = GIT_SUBMODULE_STATUS_INDEX_ADDED,
	indexDeleted = GIT_SUBMODULE_STATUS_INDEX_DELETED,
	indexModified = GIT_SUBMODULE_STATUS_INDEX_MODIFIED,
	wdUninitialized = GIT_SUBMODULE_STATUS_WD_UNINITIALIZED,
	wdAdded = GIT_SUBMODULE_STATUS_WD_ADDED,
	wdDeleted = GIT_SUBMODULE_STATUS_WD_DELETED,
	wdModified = GIT_SUBMODULE_STATUS_WD_MODIFIED,
	wdIndexModified = GIT_SUBMODULE_STATUS_WD_INDEX_MODIFIED,
	wdWDModified = GIT_SUBMODULE_STATUS_WD_WD_MODIFIED,
	wdUntracked = GIT_SUBMODULE_STATUS_WD_UNTRACKED,
	inFlagsMask = GIT_SUBMODULE_STATUS__IN_FLAGS,
	indexFlagsMask = GIT_SUBMODULE_STATUS__INDEX_FLAGS,
	wdFlagsMask = GIT_SUBMODULE_STATUS__WD_FLAGS,
}
