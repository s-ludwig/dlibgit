module git2.index;

import git2.indexer;
import git2.oid;
import git2.types;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

enum 
{
    GIT_INDEXCAP_IGNORE_CASE = 1,
    GIT_INDEXCAP_NO_FILEMODE = 2,
    GIT_INDEXCAP_NO_SYMLINKS = 4,
    GIT_INDEXCAP_FROM_OWNER = -1
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
