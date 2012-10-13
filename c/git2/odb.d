module git2.odb;

import git2.oid;
import git2.types;

extern(C):

int git_odb_add_alternate(git_odb* odb, git_odb_backend* backend, int priority);
int git_odb_add_backend(git_odb* odb, git_odb_backend* backend, int priority);
int git_odb_exists(git_odb* db, const(git_oid)* id);
int git_odb_foreach(git_odb* db, int function(git_oid*, void*) cb, void* data);
void git_odb_free(git_odb* db);
int git_odb_hash(git_oid* id, const(void)* data, size_t len, git_otype type);
int git_odb_hashfile(git_oid* _out, const(char)* path, git_otype type);
int git_odb_new(git_odb** _out);
const(void)* git_odb_object_data(git_odb_object* _object);
void git_odb_object_free(git_odb_object* _object);
const(git_oid)* git_odb_object_id(git_odb_object* _object);
size_t git_odb_object_size(git_odb_object* _object);
git_otype git_odb_object_type(git_odb_object* _object);
int git_odb_open(git_odb** _out, const(char)* objects_dir);
int git_odb_open_rstream(git_odb_stream** stream, git_odb* db, const(git_oid)* oid);
int git_odb_open_wstream(git_odb_stream** stream, git_odb* db, size_t size, git_otype type);
int git_odb_read(git_odb_object** _out, git_odb* db, const(git_oid)* id);
int git_odb_read_header(size_t* len_p, git_otype* type_p, git_odb* db, const(git_oid)* id);
int git_odb_read_prefix(git_odb_object** _out, git_odb* db, const(git_oid)* short_id, size_t len);
int git_odb_write(git_oid* oid, git_odb* odb, const(void)* data, size_t len, git_otype type);
