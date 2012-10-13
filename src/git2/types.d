module git2.types;

import git2.config;
import git2.net;
import git2.odb_backend;
import git2.remote;

import core.stdc.stdint;

alias core.stdc.stdint.int32_t int32_t;
alias core.stdc.stdint.int64_t int64_t;
alias core.stdc.stdint.uint16_t uint16_t;
alias core.stdc.stdint.uint32_t uint32_t;
alias long off64_t;
alias long __time64_t;

extern(C):

enum git_otype
{
    GIT_OBJ_ANY = -2,
    GIT_OBJ_BAD = -1,
    GIT_OBJ__EXT1 = 0,
    GIT_OBJ_COMMIT = 1,
    GIT_OBJ_TREE = 2,
    GIT_OBJ_BLOB = 3,
    GIT_OBJ_TAG = 4,
    GIT_OBJ__EXT2 = 5,
    GIT_OBJ_OFS_DELTA = 6,
    GIT_OBJ_REF_DELTA = 7
}

enum git_filemode_t
{
    GIT_FILEMODE_NEW = 0,
    GIT_FILEMODE_TREE = 16384,
    GIT_FILEMODE_BLOB = 33188,
    GIT_FILEMODE_BLOB_EXECUTABLE = 33261,
    GIT_FILEMODE_LINK = 40960,
    GIT_FILEMODE_COMMIT = 57344
}

enum git_ref_t
{
    GIT_REF_INVALID = 0,
    GIT_REF_OID = 1,
    GIT_REF_SYMBOLIC = 2,
    GIT_REF_PACKED = 4,
    GIT_REF_HAS_PEEL = 8,
    GIT_REF_LISTALL = 7
}

enum git_reset_type
{
    GIT_RESET_SOFT = 1,
    GIT_RESET_MIXED = 2,
    GIT_RESET_HARD = 3
}

enum git_branch_t
{
    GIT_BRANCH_LOCAL = 1,
    GIT_BRANCH_REMOTE = 2
}

alias git2.config.git_config_file git_config_file;
alias git2.odb_backend.git_odb_backend git_odb_backend;
alias git2.odb_backend.git_odb_stream git_odb_stream;
alias off64_t git_off_t;
alias git2.remote.git_remote_callbacks git_remote_callbacks;
alias git2.net.git_remote_head git_remote_head;
alias __time64_t git_time_t;

struct git_blob { }

struct git_commit { }

struct git_config { }

struct git_index { }

struct git_note { }

struct git_object { }

struct git_odb { }

struct git_odb_object { }

struct git_reference { }

struct git_reflog { }

struct git_reflog_entry { }

struct git_refspec { }

struct git_remote { }

struct git_repository { }

struct git_revwalk { }

struct git_signature 
{
    char* name;
    char* email;
    git_time when;
}

struct git_tag { }

struct git_time 
{
    git_time_t time;
    int offset;
}

struct git_tree { }

struct git_tree_entry { }

struct git_treebuilder { }
