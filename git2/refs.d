module git2.refs;

import git2.common;
import git2.oid;
import git2.types;

extern(C):

enum 
{
    GIT_REF_FORMAT_NORMAL = 0,
    GIT_REF_FORMAT_ALLOW_ONELEVEL = 1,
    GIT_REF_FORMAT_REFSPEC_PATTERN = 2
}

int git_reference_cmp(git_reference* ref1, git_reference* ref2);
int git_reference_create_oid(git_reference** ref_out, git_repository* repo, const(char)* name, const(git_oid)* id, int force);
int git_reference_create_symbolic(git_reference** ref_out, git_repository* repo, const(char)* name, const(char)* target, int force);
int git_reference_delete(git_reference* _ref);
int git_reference_foreach(git_repository* repo, uint list_flags, int function(const(char)*, void*) callback, void* payload);
int git_reference_foreach_glob(git_repository* repo, const(char)* glob, uint list_flags, int function(const(char)*, void*) callback, void* payload);
void git_reference_free(git_reference* _ref);
int git_reference_has_log(git_reference* _ref);
int git_reference_is_branch(git_reference* _ref);
int git_reference_is_packed(git_reference* _ref);
int git_reference_is_remote(git_reference* _ref);
int git_reference_is_valid_name(const(char)* refname);
int git_reference_list(git_strarray* array, git_repository* repo, uint list_flags);
int git_reference_lookup(git_reference** reference_out, git_repository* repo, const(char)* name);
const(char)* git_reference_name(git_reference* _ref);
int git_reference_name_to_oid(git_oid* _out, git_repository* repo, const(char)* name);
int git_reference_normalize_name(char* buffer_out, size_t buffer_size, const(char)* name, uint flags);
const(git_oid)* git_reference_oid(git_reference* _ref);
git_repository* git_reference_owner(git_reference* _ref);
int git_reference_packall(git_repository* repo);
int git_reference_peel(git_object** _out, git_reference* _ref, git_otype type);
int git_reference_reload(git_reference* _ref);
int git_reference_rename(git_reference* _ref, const(char)* new_name, int force);
int git_reference_resolve(git_reference** resolved_ref, git_reference* _ref);
int git_reference_set_oid(git_reference* _ref, const(git_oid)* id);
int git_reference_set_target(git_reference* _ref, const(char)* target);
const(char)* git_reference_target(git_reference* _ref);
git_ref_t git_reference_type(git_reference* _ref);
