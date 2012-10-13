module git2._object;

import git2.oid;
import git2.types;

extern(C):

size_t git_object__size(git_otype type);
void git_object_free(git_object* _object);
const(git_oid)* git_object_id(const(git_object)* obj);
int git_object_lookup(git_object** _object, git_repository* repo, const(git_oid)* id, git_otype type);
int git_object_lookup_prefix(git_object** object_out, git_repository* repo, const(git_oid)* id, size_t len, git_otype type);
git_repository* git_object_owner(const(git_object)* obj);
int git_object_peel(git_object** peeled, git_object* _object, git_otype target_type);
git_otype git_object_string2type(const(char)* str);
git_otype git_object_type(const(git_object)* obj);
const(char)* git_object_type2string(git_otype type);
int git_object_typeisloose(git_otype type);
