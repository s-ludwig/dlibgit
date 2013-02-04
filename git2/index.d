module git2.index;

import git2.indexer;
import git2.oid;
import git2.types;

extern(C):

enum {
	GIT_IDXENTRY_NAMEMASK  = (0x0fff),
	GIT_IDXENTRY_STAGEMASK = (0x3000),
	GIT_IDXENTRY_EXTENDED  = (0x4000),
	GIT_IDXENTRY_VALID     = (0x8000),
	GIT_IDXENTRY_STAGESHIFT = 12,

	GIT_IDXENTRY_UPDATE            = (1 << 0),
	GIT_IDXENTRY_REMOVE            = (1 << 1),
	GIT_IDXENTRY_UPTODATE          = (1 << 2),
	GIT_IDXENTRY_ADDED             = (1 << 3),

	GIT_IDXENTRY_HASHED            = (1 << 4),
	GIT_IDXENTRY_UNHASHED          = (1 << 5),
	GIT_IDXENTRY_WT_REMOVE         = (1 << 6),
	GIT_IDXENTRY_CONFLICTED        = (1 << 7),

	GIT_IDXENTRY_UNPACKED          = (1 << 8),
	GIT_IDXENTRY_NEW_SKIP_WORKTREE = (1 << 9),

	GIT_IDXENTRY_INTENT_TO_ADD     = (1 << 13),
	GIT_IDXENTRY_SKIP_WORKTREE     = (1 << 14),
	GIT_IDXENTRY_EXTENDED2         = (1 << 15),

	GIT_IDXENTRY_EXTENDED_FLAGS = (GIT_IDXENTRY_INTENT_TO_ADD | GIT_IDXENTRY_SKIP_WORKTREE)
}

struct git_index_time {
	git_time_t seconds;
	uint nanoseconds;
}

struct git_index_entry {
	git_index_time ctime;
	git_index_time mtime;

	uint dev;
	uint ino;
	uint mode;
	uint uid;
	uint gid;
	git_off_t file_size;

	git_oid oid;

	ushort flags;
	ushort flags_extended;

	char *path;
}

struct git_index_reuc_entry {
	uint mode[3];
	git_oid oid[3];
	char *path;
}

enum {
	GIT_INDEXCAP_IGNORE_CASE = 1,
	GIT_INDEXCAP_NO_FILEMODE = 2,
	GIT_INDEXCAP_NO_SYMLINKS = 4,
	GIT_INDEXCAP_FROM_OWNER  = ~0u
}

int git_index_open(git_index** out_, const(char)* index_path);
int git_index_new(git_index** out_);
void git_index_free(git_index* index);
git_repository* git_index_owner(const(git_index)* index);
uint git_index_caps(const(git_index)* index);
int git_index_set_caps(git_index* index, uint caps);
int git_index_read(git_index* index);
int git_index_write(git_index* index);
int git_index_read_tree(git_index* index, const(git_tree)* tree);
int git_index_write_tree(git_oid* out_, git_index* index);
int git_index_write_tree_to(git_oid* out_, git_index* index, git_repository *repo);
size_t git_index_entrycount(const(git_index)* index);
void git_index_clear(git_index* index);
const(git_index_entry)* git_index_get_byindex(git_index* index, size_t n);
const(git_index_entry)* git_index_get_bypath(git_index* index, const(char)* path, int stage);
int git_index_remove(git_index* index, const(char)* path, int stage);
int git_index_remove_directory(git_index* index, const(char)* dir, int stage);
int git_index_add(git_index* index, const(git_index_entry)* source_entry);
int git_index_entry_stage(const(git_index_entry)* entry);
int git_index_add_bypath(git_index* index, const(char)* path);
int git_index_remove_bypath(git_index* index, const(char)* path);
int git_index_find(size_t* at_pos, git_index* index, const(char)* path);
int git_index_conflict_add(git_index* index,
	const(git_index_entry)* ancestor_entry,
	const(git_index_entry)* our_entry,
	const(git_index_entry)* their_entry);
int git_index_conflict_get(git_index_entry** ancestor_out_, git_index_entry** our_out_, git_index_entry** their_out_, git_index* index, const(char)* path);
int git_index_conflict_remove(git_index* index, const(char)* path);
void git_index_conflict_cleanup(git_index* index);
int git_index_has_conflicts(const(git_index)* index);
uint git_index_reuc_entrycount(git_index* index);
int git_index_reuc_find(size_t* at_pos, git_index* index, const(char)* path);
const(git_index_reuc_entry)* git_index_reuc_get_bypath(git_index* index, const(char)* path);
const(git_index_reuc_entry)* git_index_reuc_get_byindex(git_index* index, size_t n);
int git_index_reuc_add(git_index* index, const(char)* path,
	int ancestor_mode, git_oid* ancestor_id,
	int our_mode, git_oid* our_id,
	int their_mode, git_oid* their_id);
int git_index_reuc_remove(git_index* index, size_t n);
