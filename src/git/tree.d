/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.tree;

import git.object_;
import git.oid;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.tree;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;
import std.exception : enforce;


///
GitTree lookupTree(GitRepo repo, GitOid id)
{
	git_tree* tree;
	require(git_tree_lookup(&tree, repo.cHandle, &id._get_oid()) == 0);
	return GitTree(repo, tree);
}

///
GitTree lookupTree(GitRepo repo, GitOid id, size_t id_length)
{
	git_tree* tree;
	require(git_tree_lookup_prefix(&tree, repo.cHandle, &id._get_oid(), id_length) == 0);
	return GitTree(repo, tree);
}

GitTreeBuilder createTreeBuilder()
{
	return GitTreeBuilder(false);
}

GitTreeBuilder createTreeBuilder(GitTree source)
{
	return GitTreeBuilder(source);
}


///
struct GitTree {
	package this(GitRepo repo, git_tree* tree)
	{
		_object = GitObject(repo, cast(git_object*)tree);
	}

	this(GitObject object)
	{
		enforce(object.type == GitType.tree, "GIT object is not a tree.");
		_object = object;
	}

	@property GitOid id() { return GitOid(*git_tree_id(this.cHandle)); }
	@property GitRepo owner() { return _object.owner; }

	@property size_t entryCount() { return git_tree_entrycount(this.cHandle); }

	GitTreeEntry getEntryByName(string filename)
	{
		auto ret = git_tree_entry_byname(this.cHandle, filename.toStringz());
		enforce(ret !is null, "Couldn't find tree entry "~filename); // FIXME: use return value
		return GitTreeEntry(this, ret);
	}

	GitTreeEntry getEntryByIndex(size_t index)
	{
		auto ret = git_tree_entry_byindex(this.cHandle, index);
		enforce(ret !is null, "Couldn't find tree entry at "~index.to!string); // FIXME: use return value
		return GitTreeEntry(this, ret);
	}

	GitTreeEntry getEntryById(GitOid oid)
	{
		auto ret = git_tree_entry_byid(this.cHandle, &oid._get_oid());
		enforce(ret !is null, "Couldn't find tree entry "~oid.toHex()); // FIXME: use return value
		return GitTreeEntry(this, ret);
	}

	GitTreeEntry getEntryByPath(string path)
	{
		git_tree_entry* ret;
		require(git_tree_entry_bypath(&ret, this.cHandle, path.toStringz()) == 0);
		return GitTreeEntry(this.owner, ret);
	}

	void walk(GitTreewalkMode mode, scope GitTreewalkDelegate del)
	{
		struct CTX { GitTreewalkDelegate del; GitTree tree; }

		static extern(C) nothrow int callback(const(char)* root, const(git_tree_entry)* entry, void *payload)
		{
			auto ctx = cast(CTX*)payload;
			try {
				final switch (ctx.del(root.to!string(), GitTreeEntry(ctx.tree, entry))) {
					case ContinueWalkSkip.yes: return 0;
					case ContinueWalkSkip.no: return -1;
					case ContinueWalkSkip.skip: return 1;
				}
			} catch (Exception e) return -1;
		}

		auto ctx = CTX(del, this);
		require(git_tree_walk(this.cHandle, cast(git_treewalk_mode)mode, &callback, cast(void*)&ctx) == 0);
	}

	package @property inout(git_tree)* cHandle() inout { return cast(inout(git_tree)*)_object.cHandle; }

	private GitObject _object;
}


///
enum GitTreewalkMode {
	pre = GIT_TREEWALK_PRE,
	post = GIT_TREEWALK_POST
}

///
alias GitTreewalkDelegate = ContinueWalkSkip delegate(string root, GitTreeEntry entry);


///
struct GitTreeBuilder {
	private this(bool dummy)
	{
		git_treebuilder* builder;
		require(git_treebuilder_new(&builder, null, null) == 0);
		_data = Data(builder);
	}

	private this(GitTree src)
	{
		git_treebuilder* builder;
        require(git_treebuilder_new(&builder, null, src.cHandle) == 0);
		_data = Data(builder);
	}

	@property size_t entryCount() { return git_treebuilder_entrycount(this.cHandle); }

	void clear() { git_treebuilder_clear(this.cHandle); }

	GitTreeEntry get(string filename)
	{
		return GitTreeEntry(this, git_treebuilder_get(this.cHandle, filename.toStringz()));
	}

	GitTreeEntry insert(string filename, GitOid id, GitFileModeType filemode)
	{
		const(git_tree_entry)* ret;
		require(git_treebuilder_insert(&ret, this.cHandle, filename.toStringz(), &id._get_oid(), cast(git_filemode_t) filemode) == 0);
		return GitTreeEntry(this, ret);
	}

	void remove(string filename)
	{
		require(git_treebuilder_remove(this.cHandle, filename.toStringz()) == 0);
	}

	// return false from the callback to remove the item
	void filter(scope bool delegate(GitTreeEntry entry) del)
	{
		struct CTX { bool delegate(GitTreeEntry) del; GitTreeBuilder builder; bool exception; }

		static extern(C) nothrow int callback(const(git_tree_entry)* entry, void *payload)
		{
			auto ctx = cast(CTX*)payload;
			if (ctx.exception) return 0;
			try {
				return ctx.del(GitTreeEntry(ctx.builder, entry)) ? 0 : 1;
			} catch (Exception e) {
				ctx.exception = true;
				return 0;
			}
		}

		auto ctx = CTX(del, this, false);
		git_treebuilder_filter(this.cHandle, &callback, cast(void*)&ctx);
	}

	GitOid write(GitRepo repo)
	{
		GitOid ret;
		require(git_treebuilder_write(&ret._get_oid(), repo.cHandle, this.cHandle) == 0);
		return ret;
	}


	mixin RefCountedGitObject!(git_treebuilder, git_treebuilder_free);
}


///
struct GitTreeEntry {
	package this(GitTree owner, const(git_tree_entry)* entry)
	{
		_tree = owner;
		_repo = _tree.owner;
		_entry = entry;
	}

	package this(GitTreeBuilder owner, const(git_tree_entry)* entry)
	{
		_builder = owner;
		_tree = GitTree.init;
		_repo = GitRepo.init;
		_entry = entry;
	}

	package this(GitRepo owner, git_tree_entry* entry)
	{
		_tree = GitTree.init;
		_repo = owner;
		_data = Data(entry);
	}

	@property string name() { return git_tree_entry_name(cHandle()).to!string(); }
	@property GitOid id() { return GitOid(*git_tree_entry_id(cHandle())); }
	@property GitType type() { return cast(GitType)git_tree_entry_type(cHandle()); }
	@property GitFileModeType fileMode() { return cast(GitFileModeType)git_tree_entry_filemode(cHandle()); }

	static if (targetLibGitVersion >= VersionInfo(0, 20, 0))
		@property GitFileModeType fileModeRaw() { return cast(GitFileModeType)git_tree_entry_filemode_raw(cHandle()); }

	@property GitTreeEntry dup() { return GitTreeEntry(_repo, git_tree_entry_dup(cHandle())); }

	GitObject toObject()
	{
		git_object* ret;
		require(git_tree_entry_to_object(&ret, _repo.cHandle, cHandle()) == 0);
		return GitObject(_repo, ret);
	}

	int opCmp(GitTreeEntry other) { return git_tree_entry_cmp(cHandle(), other.cHandle()); }
	bool opEquals(GitTreeEntry other) { return opCmp(other) == 0; }


	package const(git_tree_entry)* cHandle() { return _entry ? _entry : _data._payload; }

	mixin RefCountedGitObject!(git_tree_entry, git_tree_entry_free, false);

private:
	// foreign ownership
	GitTreeBuilder _builder;
	GitTree _tree;
	GitRepo _repo;
	const(git_tree_entry)* _entry;
}
