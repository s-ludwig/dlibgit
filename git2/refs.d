module git2.refs;

import git2.common;
import git2.oid;
import git2.types;

extern(C):


alias git_reference_foreach_cb = int function(const(char)* refname, void *payload);

enum git_reference_normalize {
	GIT_REF_FORMAT_NORMAL = 0,
	GIT_REF_FORMAT_ALLOW_ONELEVEL = (1 << 0),
	GIT_REF_FORMAT_REFSPEC_PATTERN = (1 << 1),
}


int git_reference_lookup(git_reference** out_, git_repository* repo, const(char)* name);
int git_reference_name_to_id(
	git_oid* out_, git_repository* repo, const(char)* name);
int git_reference_symbolic_create(git_reference** out_, git_repository* repo, const(char)* name, const(char)* target, int force);
int git_reference_create(git_reference** out_, git_repository* repo, const(char)* name, const git_oid* id, int force);
const(git_oid)*  git_reference_target(const(git_reference)* ref_);
const(char)* git_reference_symbolic_target(const(git_reference)* ref_);
git_ref_t git_reference_type(const(git_reference)* ref_);
const(char)* git_reference_name(const(git_reference)* ref_);
int git_reference_resolve(git_reference** out_, const(git_reference)* ref_);
git_repository*  git_reference_owner(const(git_reference)* ref_);
int git_reference_symbolic_set_target(git_reference* ref_, const(char)* target);
int git_reference_set_target(git_reference* ref_, const git_oid* id);
int git_reference_rename(git_reference* ref_, const(char)* name, int force);
int git_reference_delete(git_reference* ref_);
int git_reference_packall(git_repository* repo);
int git_reference_list(git_strarray *array, git_repository* repo, uint list_flags);
int git_reference_foreach(
	git_repository* repo,
	uint list_flags,
	git_reference_foreach_cb callback,
	void *payload);
int git_reference_is_packed(git_reference* ref_);
int git_reference_reload(git_reference* ref_);
void git_reference_free(git_reference* ref_);
int git_reference_cmp(git_reference* ref1, git_reference* ref2);
int git_reference_foreach_glob(
	git_repository* repo,
	const(char)* glob,
	uint list_flags,
	git_reference_foreach_cb callback,
	void *payload);
int git_reference_has_log(git_reference* ref_);
int git_reference_is_branch(git_reference* ref_);
int git_reference_is_remote(git_reference* ref_);

int git_reference_normalize_name(
	char *buffer_out_,
	size_t buffer_size,
	const(char)* name,
	git_reference_normalize flags);
int git_reference_peel(
	git_object** out_,
	git_reference* ref_,
	git_otype type);
int git_reference_is_valid_name(const(char)* refname);
