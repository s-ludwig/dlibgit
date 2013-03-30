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
    ANY = -2,
    BAD = -1,
    _EXT1 = 0,
    COMMIT = 1,
    TREE = 2,
    BLOB = 3,
    TAG = 4,
    _EXT2 = 5,
    OFS_DELTA = 6,
    REF_DELTA = 7
}

enum git_filemode_t
{
    NEW = 0,
    TREE = 16384,
    BLOB = 33188,
    BLOB_EXECUTABLE = 33261,
    LINK = 40960,
    COMMIT = 57344
}

enum git_ref_t
{
    INVALID = 0,
    OID = 1,
    SYMBOLIC = 2,
    PACKED = 4,
    HAS_PEEL = 8,
    LISTALL = 7
}

enum git_reset_type
{
    SOFT = 1,
    MIXED = 2,
    HARD = 3
}

enum git_branch_t
{
    LOCAL = 1,
    REMOTE = 2
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

struct git_push {}

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
