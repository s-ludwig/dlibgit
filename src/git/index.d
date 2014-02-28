/*
 *             Copyright Sönke Ludwig 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.index;

import git.commit;
import git.oid;
import git.tree;
import git.repository;
import git.types;
import git.util;
import git.version_;

import deimos.git2.index;
import deimos.git2.errors;
import deimos.git2.types;

import std.conv : to;
import std.string : toStringz;


GitIndex openIndex(string index_path)
{
	git_index* dst;
	require(git_index_open(&dst, index_path.toStringz) == 0);
	return GitIndex(dst);
}

GitIndex createIndex()
{
	git_index* dst;
	require(git_index_new(&dst) == 0);
	return GitIndex(dst);
}

struct GitIndex {
	this(git_index* index)
	{
		_repo = GitRepo.init;
		_data = Data(index);
	}

	this(GitRepo repo, git_index* index)
	{
		_repo = repo;
		_data = Data(index);
	}

	@property inout(GitRepo) owner() inout { return _repo; }

	@property GitIndexCaps caps() { return cast(GitIndexCaps)git_index_caps(this.cHandle); }
	@property void caps(GitIndexCaps caps) { require(git_index_set_caps(this.cHandle, caps) == 0); }

	@property string path() { return git_index_path(this.cHandle).to!string; }

	@property size_t entryCount() { return git_index_entrycount(this.cHandle); }

	void read(bool force) { require(git_index_read(this.cHandle, force) == 0); }
	void write() { require(git_index_write(this.cHandle) == 0); }

	void readTree(in GitTree tree) { require(git_index_read_tree(this.cHandle, tree.cHandle) == 0); }
	GitOid writeTree()
	{
		GitOid ret;
		require(git_index_write_tree(&ret._get_oid(), this.cHandle) == 0);
		return ret;
	}
	GitOid writeTree(GitRepo repo)
	{
		GitOid ret;
		require(git_index_write_tree_to(&ret._get_oid(), this.cHandle, repo.cHandle) == 0);
		return ret;
	}

	void clear() { git_index_clear(this.cHandle); }

	GitIndexEntry get(size_t n) { return GitIndexEntry(this, git_index_get_byindex(this.cHandle, n)); }
	GitIndexEntry get(string path, int stage) { return GitIndexEntry(this, git_index_get_bypath(this.cHandle, path.toStringz, stage)); }

	void remove(string path, int stage) { require(git_index_remove(this.cHandle, path.toStringz, stage) == 0); }
	void removeDirectory(string dir, int stage) { require(git_index_remove_directory(this.cHandle, dir.toStringz, stage) == 0); }
	void add(GitIndexEntry source_entry) { require(git_index_add(this.cHandle, source_entry.cHandle) == 0); }
	void addByPath(string path) { require(git_index_add_bypath(this.cHandle, path.toStringz) == 0); }
	void removeByPath(string path) { require(git_index_remove_bypath(this.cHandle, path.toStringz) == 0); }

/*
int git_index_add_all(
	git_index *index,
	const(git_strarray)* pathspec,
	uint flags,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_remove_all(
	git_index *index,
	const(git_strarray)* pathspec,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_update_all(
	git_index *index,
	const(git_strarray)* pathspec,
	git_index_matched_path_cb callback,
	void *payload);
int git_index_find(size_t *at_pos, git_index *index, const(char)* path);
int git_index_conflict_add(
	git_index *index,
	const(git_index_entry)* ancestor_entry,
	const(git_index_entry)* our_entry,
	const(git_index_entry)* their_entry);
int git_index_conflict_get(
	const(git_index_entry)** ancestor_out,
	const(git_index_entry)** our_out,
	const(git_index_entry)** their_out,
	git_index *index,
	const(char)* path);
int git_index_conflict_remove(git_index *index, const(char)* path);
void git_index_conflict_cleanup(git_index *index);
int git_index_has_conflicts(const(git_index)* index);
int git_index_conflict_iterator_new(
	git_index_conflict_iterator **iterator_out,
	git_index *index);
int git_index_conflict_next(
	const(git_index_entry)** ancestor_out,
	const(git_index_entry)** our_out,
	const(git_index_entry)** their_out,
	git_index_conflict_iterator *iterator);
void git_index_conflict_iterator_free(
	git_index_conflict_iterator *iterator);
int git_index_entry_stage(const(git_index_entry)* entry);*/

	mixin RefCountedGitObject!(git_index, git_index_free);
	private GitRepo _repo;
}

struct GitIndexEntry {
	package this(GitIndex index, const(git_index_entry)* entry)
	{
		_index = index;
		_entry = entry;
	}

	//@property SysTime ctime() const { return gitIndexTimeToSysTime(_entry.ctime); }
	//@property SysTime mtime() const { return gitIndexTimeToSysTime(_entry.mtime); }
	@property uint dev() const { return _entry.dev; }
	@property uint ino() const { return _entry.ino; }
	@property uint mode() const { return _entry.mode; }
	@property uint uid() const { return _entry.uid; }
	@property uint gid() const { return _entry.gid; }
	@property ulong fileSize() const { return _entry.file_size; }
	@property GitOid oid() const { return GitOid(_entry.oid); }
	@property string path() const { return _entry.path.to!string; }
	@property int stage() { return git_index_entry_stage(_entry); }

	//ushort flags;
	//ushort flags_extended;

	package @property const(git_index_entry)* cHandle() const { return _entry; }

	private const(git_index_entry)* _entry;
	private GitIndex _index;
}

enum GitIndexCaps {
	none = 0,
	ignoreCase = GIT_INDEXCAP_IGNORE_CASE,
	noFilemode = GIT_INDEXCAP_NO_FILEMODE,
	noSymlinks = GIT_INDEXCAP_NO_SYMLINKS,
	fromOwner = GIT_INDEXCAP_FROM_OWNER
}

/*struct git_index_time {
	git_time_t seconds;
	uint nanoseconds;
}

enum GIT_IDXENTRY_NAMEMASK   = (0x0fff);
enum GIT_IDXENTRY_STAGEMASK  = (0x3000);
enum GIT_IDXENTRY_EXTENDED   = (0x4000);
enum GIT_IDXENTRY_VALID      = (0x8000);
enum GIT_IDXENTRY_STAGESHIFT = 12;

auto GIT_IDXENTRY_STAGE(T)(T E) { return (((E).flags & GIT_IDXENTRY_STAGEMASK) >> GIT_IDXENTRY_STAGESHIFT); }

enum GIT_IDXENTRY_INTENT_TO_ADD     = (1 << 13);
enum GIT_IDXENTRY_SKIP_WORKTREE     = (1 << 14);
enum GIT_IDXENTRY_EXTENDED2         = (1 << 15);
enum GIT_IDXENTRY_EXTENDED_FLAGS = (GIT_IDXENTRY_INTENT_TO_ADD | GIT_IDXENTRY_SKIP_WORKTREE);

enum GIT_IDXENTRY_UPDATE            = (1 << 0);
enum GIT_IDXENTRY_REMOVE            = (1 << 1);
enum GIT_IDXENTRY_UPTODATE          = (1 << 2);
enum GIT_IDXENTRY_ADDED             = (1 << 3);

enum GIT_IDXENTRY_HASHED            = (1 << 4);
enum GIT_IDXENTRY_UNHASHED          = (1 << 5);
enum GIT_IDXENTRY_WT_REMOVE         = (1 << 6);
enum GIT_IDXENTRY_CONFLICTED        = (1 << 7);

enum GIT_IDXENTRY_UNPACKED          = (1 << 8);
enum GIT_IDXENTRY_NEW_SKIP_WORKTREE = (1 << 9);


alias git_index_matched_path_cb = int function(
	const(char)* path, const(char)* matched_pathspec, void *payload);

enum git_index_add_option_t {
	GIT_INDEX_ADD_DEFAULT = 0,
	GIT_INDEX_ADD_FORCE = (1u << 0),
	GIT_INDEX_ADD_DISABLE_PATHSPEC_MATCH = (1u << 1),
	GIT_INDEX_ADD_CHECK_PATHSPEC = (1u << 2),
}

enum GIT_INDEX_STAGE_ANY = -1;
*/
