module showindex;

import git2.blob;
import git2._object;
import git2.index;
import git2.repository;
import git2.types;
import git2.oid;

import std.stdio;
import std.string;
import std.exception;

void main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Must pass path to .git folder.");
        return;
    }
    
    size_t i, ecount;
    git_oid oid;

    char[41] _out = '\0';

    git_repository* repo;
    auto res = git_repository_open(&repo, toStringz(args[1]));

    git_index* index;
    git_repository_index(&index, repo);
    git_index_read(index);

    ecount = git_index_entrycount(index);
    
    for (i = 0; i < ecount; ++i)
    {
        git_index_entry* e = git_index_get(index, i);

        oid = e.oid;
        git_oid_fmt(_out.ptr, &oid);
        
        printf("File Path: %s\n", e.path);
        printf(" Blob SHA: %s\n", &_out);
        printf("File Size: %d\n", cast(int)e.file_size);
        printf("   Device: %d\n", cast(int)e.dev);
        printf("    Inode: %d\n", cast(int)e.ino);
        printf("      UID: %d\n", cast(int)e.uid);
        printf("      GID: %d\n", cast(int)e.gid);
        printf("    ctime: %d\n", cast(int)e.ctime.seconds);
        printf("    mtime: %d\n", cast(int)e.mtime.seconds);
        printf("\n");
    }

    git_index_free(index);

    git_repository_free(repo);
}
