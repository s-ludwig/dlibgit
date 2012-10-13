module git2.index;

import git2.indexer;
import git2.oid;
import git2.types;

extern(C):

enum GIT_IDXENTRY_NAMEMASK          = 0x0fff;
enum GIT_IDXENTRY_STAGEMASK         = 0x3000;
enum GIT_IDXENTRY_EXTENDED          = 0x4000;
enum GIT_IDXENTRY_VALID             = 0x8000;
enum GIT_IDXENTRY_STAGESHIFT        = 12;
enum GIT_IDXENTRY_UPDATE            = 1 << 0;
enum GIT_IDXENTRY_REMOVE            = 1 << 1;
enum GIT_IDXENTRY_UPTODATE          = 1 << 2;
enum GIT_IDXENTRY_ADDED             = 1 << 3;
enum GIT_IDXENTRY_HASHED            = 1 << 4;
enum GIT_IDXENTRY_UNHASHED          = 1 << 5;
enum GIT_IDXENTRY_WT_REMOVE         = 1 << 6; /* remove in work directory */
enum GIT_IDXENTRY_CONFLICTED        = 1 << 7;
enum GIT_IDXENTRY_UNPACKED          = 1 << 8;
enum GIT_IDXENTRY_NEW_SKIP_WORKTREE = 1 << 9;
enum GIT_IDXENTRY_INTENT_TO_ADD     = 1 << 13;
enum GIT_IDXENTRY_SKIP_WORKTREE     = 1 << 14;
enum GIT_IDXENTRY_EXTENDED2         = 1 << 15;
enum GIT_IDXENTRY_EXTENDED_FLAGS    = GIT_IDXENTRY_INTENT_TO_ADD | GIT_IDXENTRY_SKIP_WORKTREE;

enum
{
    GIT_INDEXCAP_IGNORE_CASE = 1,
    GIT_INDEXCAP_NO_FILEMODE = 2,
    GIT_INDEXCAP_NO_SYMLINKS = 4,
    GIT_INDEXCAP_FROM_OWNER  = -1
}


struct git_index_entry
{
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
    char* path;
}


struct git_index_entry_unmerged
{
    uint[3] mode;
    git_oid[3] oid;
    char* path;
}


struct git_index_time
{
    git_time_t seconds;
    uint nanoseconds;
}


int git_index_add(git_index* index, const(char)* path, int stage);
int git_index_add2(git_index* index, const(git_index_entry)* source_entry);
int git_index_append(git_index* index, const(char)* path, int stage);
int git_index_append2(git_index* index, const(git_index_entry)* source_entry);
uint git_index_caps(const(git_index)* index);
void git_index_clear(git_index* index);
int git_index_entry_stage(const(git_index_entry)* entry);
uint git_index_entrycount(git_index* index);
uint git_index_entrycount_unmerged(git_index* index);
int git_index_find(git_index* index, const(char)* path);
void git_index_free(git_index* index);
git_index_entry* git_index_get(git_index* index, size_t n);
const(git_index_entry_unmerged)* git_index_get_unmerged_byindex(git_index* index, size_t n);
const(git_index_entry_unmerged)* git_index_get_unmerged_bypath(git_index* index, const(char)* path);
int git_index_open(git_index** index, const(char)* index_path);
int git_index_read(git_index* index);
int git_index_read_tree(git_index* index, git_tree* tree, git_indexer_stats* stats);
int git_index_remove(git_index* index, int position);
int git_index_set_caps(git_index* index, uint caps);
void git_index_uniq(git_index* index);
int git_index_write(git_index* index);
