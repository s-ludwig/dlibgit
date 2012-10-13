module git2.blob;

import git2._object;
import git2.oid;
import git2.types;

extern(C):

/** GIT_INLINE */
void git_blob_free(git_blob* blob)
{
    git_object_free(cast(git_object *) blob);
}

/** GIT_INLINE */
int git_blob_lookup(git_blob** blob, git_repository* repo, const(git_oid)* id)
{
    return git_object_lookup(cast(git_object **)blob, repo, id, git_otype.GIT_OBJ_BLOB);
}

/** GIT_INLINE */
int git_blob_lookup_prefix(git_blob** blob, git_repository* repo, const(git_oid)* id, size_t len)
{
    return git_object_lookup_prefix(cast(git_object **)blob, repo, id, len, git_otype.GIT_OBJ_BLOB);
}

int git_blob_create_frombuffer(git_oid* oid, git_repository* repo, const(void)* buffer, size_t len);
int git_blob_create_fromchunks(git_oid* oid, git_repository* repo, const(char)* hintpath, int function(char*, size_t, void*) source_cb, void* payload);
int git_blob_create_fromdisk(git_oid* oid, git_repository* repo, const(char)* path);
int git_blob_create_fromfile(git_oid* oid, git_repository* repo, const(char)* path);
const(void)* git_blob_rawcontent(git_blob* blob);
size_t git_blob_rawsize(git_blob* blob);
