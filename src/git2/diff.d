module git2.diff;

import git2.common;
import git2.oid;
import git2.types;
import mingw.include.stdint;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

enum 
{
    GIT_DIFF_NORMAL = 0,
    GIT_DIFF_REVERSE = 1,
    GIT_DIFF_FORCE_TEXT = 2,
    GIT_DIFF_IGNORE_WHITESPACE = 4,
    GIT_DIFF_IGNORE_WHITESPACE_CHANGE = 8,
    GIT_DIFF_IGNORE_WHITESPACE_EOL = 16,
    GIT_DIFF_IGNORE_SUBMODULES = 32,
    GIT_DIFF_PATIENCE = 64,
    GIT_DIFF_INCLUDE_IGNORED = 128,
    GIT_DIFF_INCLUDE_UNTRACKED = 256,
    GIT_DIFF_INCLUDE_UNMODIFIED = 512,
    GIT_DIFF_RECURSE_UNTRACKED_DIRS = 1024,
    GIT_DIFF_DISABLE_PATHSPEC_MATCH = 2048,
    GIT_DIFF_DELTAS_ARE_ICASE = 4096
}

enum 
{
    GIT_DIFF_FILE_VALID_OID = 1,
    GIT_DIFF_FILE_FREE_PATH = 2,
    GIT_DIFF_FILE_BINARY = 4,
    GIT_DIFF_FILE_NOT_BINARY = 8,
    GIT_DIFF_FILE_FREE_DATA = 16,
    GIT_DIFF_FILE_UNMAP_DATA = 32,
    GIT_DIFF_FILE_NO_DATA = 64
}

enum git_delta_t
{
    GIT_DELTA_UNMODIFIED = 0,
    GIT_DELTA_ADDED = 1,
    GIT_DELTA_DELETED = 2,
    GIT_DELTA_MODIFIED = 3,
    GIT_DELTA_RENAMED = 4,
    GIT_DELTA_COPIED = 5,
    GIT_DELTA_IGNORED = 6,
    GIT_DELTA_UNTRACKED = 7
}

enum 
{
    GIT_DIFF_LINE_CONTEXT = 32,
    GIT_DIFF_LINE_ADDITION = 43,
    GIT_DIFF_LINE_DELETION = 45,
    GIT_DIFF_LINE_ADD_EOFNL = 10,
    GIT_DIFF_LINE_DEL_EOFNL = 0,
    GIT_DIFF_LINE_FILE_HDR = 70,
    GIT_DIFF_LINE_HUNK_HDR = 72,
    GIT_DIFF_LINE_BINARY = 66
}

alias int function(void*, const(git_diff_delta)*, const(git_diff_range)*, char, const(char)*, size_t) git_diff_data_fn;
alias int function(void*, const(git_diff_delta)*, float) git_diff_file_fn;
alias int function(void*, const(git_diff_delta)*, const(git_diff_range)*, const(char)*, size_t) git_diff_hunk_fn;

struct git_diff_delta 
{
    git_diff_file old_file;
    git_diff_file new_file;
    git_delta_t status;
    uint similarity;
    int binary;
}

struct git_diff_file 
{
    git_oid oid;
    const(char)* path;
    git_off_t size;
    uint flags;
    uint16_t mode;
}

struct git_diff_list { }

struct git_diff_options 
{
    uint32_t flags;
    uint16_t context_lines;
    uint16_t interhunk_lines;
    char* old_prefix;
    char* new_prefix;
    git_strarray pathspec;
    git_off_t max_size;
}

struct git_diff_patch { }

struct git_diff_range 
{
    int old_start;
    int old_lines;
    int new_start;
    int new_lines;
}

int git_diff_blobs(git_blob* old_blob, git_blob* new_blob, const(git_diff_options)* options, void* cb_data, git_diff_file_fn file_cb, git_diff_hunk_fn hunk_cb, git_diff_data_fn line_cb);
int git_diff_foreach(git_diff_list* diff, void* cb_data, git_diff_file_fn file_cb, git_diff_hunk_fn hunk_cb, git_diff_data_fn line_cb);
int git_diff_get_patch(git_diff_patch** patch, const(git_diff_delta)** delta, git_diff_list* diff, size_t idx);
int git_diff_index_to_tree(git_repository* repo, const(git_diff_options)* opts, git_tree* old_tree, git_diff_list** diff);
void git_diff_list_free(git_diff_list* diff);
int git_diff_merge(git_diff_list* onto, const(git_diff_list)* from);
size_t git_diff_num_deltas(git_diff_list* diff);
size_t git_diff_num_deltas_of_type(git_diff_list* diff, git_delta_t type);
const(git_diff_delta)* git_diff_patch_delta(git_diff_patch* patch);
void git_diff_patch_free(git_diff_patch* patch);
int git_diff_patch_get_hunk(const(git_diff_range)** range, const(char)** header, size_t* header_len, size_t* lines_in_hunk, git_diff_patch* patch, size_t hunk_idx);
int git_diff_patch_get_line_in_hunk(char* line_origin, const(char)** content, size_t* content_len, int* old_lineno, int* new_lineno, git_diff_patch* patch, size_t hunk_idx, size_t line_of_hunk);
size_t git_diff_patch_num_hunks(git_diff_patch* patch);
int git_diff_patch_num_lines_in_hunk(git_diff_patch* patch, size_t hunk_idx);
int git_diff_print_compact(git_diff_list* diff, void* cb_data, git_diff_data_fn print_cb);
int git_diff_print_patch(git_diff_list* diff, void* cb_data, git_diff_data_fn print_cb);
char git_diff_status_char(git_delta_t status);
int git_diff_tree_to_tree(git_repository* repo, const(git_diff_options)* opts, git_tree* old_tree, git_tree* new_tree, git_diff_list** diff);
int git_diff_workdir_to_index(git_repository* repo, const(git_diff_options)* opts, git_diff_list** diff);
int git_diff_workdir_to_tree(git_repository* repo, const(git_diff_options)* opts, git_tree* old_tree, git_diff_list** diff);
