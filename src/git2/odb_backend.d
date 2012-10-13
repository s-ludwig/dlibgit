module git2.odb_backend;

import git2.oid;
import git2.types;

extern(C):

enum 
{
    GIT_STREAM_RDONLY = 2,
    GIT_STREAM_WRONLY = 4,
    GIT_STREAM_RW = 6
}

struct git_odb_backend 
{
    git_odb* odb;
    int function(void**, size_t*, git_otype*, git_odb_backend*, const(git_oid)*) read;
    int function(git_oid*, void**, size_t*, git_otype*, git_odb_backend*, const(git_oid)*, size_t) read_prefix;
    int function(size_t*, git_otype*, git_odb_backend*, const(git_oid)*) read_header;
    int function(git_oid*, git_odb_backend*, const(void)*, size_t, git_otype) write;
    int function(git_odb_stream**, git_odb_backend*, size_t, git_otype) writestream;
    int function(git_odb_stream**, git_odb_backend*, const(git_oid)*) readstream;
    int function(git_odb_backend*, const(git_oid)*) exists;
    int function(git_odb_backend*, int function(git_oid*, void*), void*) _foreach;
    void function(git_odb_backend*) free;
}

struct git_odb_stream 
{
    git_odb_backend* backend;
    int mode;
    int function(git_odb_stream*, char*, size_t) read;
    int function(git_odb_stream*, const(char)*, size_t) write;
    int function(git_oid*, git_odb_stream*) finalize_write;
    void function(git_odb_stream*) free;
}

int git_odb_backend_loose(git_odb_backend** backend_out, const(char)* objects_dir, int compression_level, int do_fsync);
void* git_odb_backend_malloc(git_odb_backend* backend, size_t len);
int git_odb_backend_one_pack(git_odb_backend** backend_out, const(char)* index_file);
int git_odb_backend_pack(git_odb_backend** backend_out, const(char)* objects_dir);
