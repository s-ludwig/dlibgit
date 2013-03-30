module git2.tag;

import git2._object;
import git2.common;
import git2.oid;
import git2.types;

extern(C):

/** GIT_INLINE */
int git_tag_lookup(git_tag** tag, git_repository* repo, const(git_oid)* id)
{
    return git_object_lookup(cast(git_object**)tag, repo, id, cast(git_otype)git_otype.TAG);
}

/** GIT_INLINE */
int git_tag_lookup_prefix(git_tag** tag, git_repository* repo, const(git_oid)* id, size_t len)
{
    return git_object_lookup_prefix(cast(git_object**)tag, repo, id, len, cast(git_otype)git_otype.TAG);
}

int git_tag_create(git_oid* oid, git_repository* repo, const(char)* tag_name, const(git_object)* target, const(git_signature)* tagger, const(char)* message, int force);
int git_tag_create_frombuffer(git_oid* oid, git_repository* repo, const(char)* buffer, int force);
int git_tag_create_lightweight(git_oid* oid, git_repository* repo, const(char)* tag_name, const(git_object)* target, int force);
int git_tag_delete(git_repository* repo, const(char)* tag_name);
void git_tag_free(git_tag* tag);
const(git_oid)* git_tag_id(git_tag* tag);
int git_tag_list(git_strarray* tag_names, git_repository* repo);
int git_tag_list_match(git_strarray* tag_names, const(char)* pattern, git_repository* repo);
const(char)* git_tag_message(git_tag* tag);
const(char)* git_tag_name(git_tag* tag);
int git_tag_peel(git_object** tag_target, git_tag* tag);
const(git_signature)* git_tag_tagger(git_tag* tag);
int git_tag_target(git_object** target, git_tag* tag);
const(git_oid)* git_tag_target_oid(git_tag* tag);
git_otype git_tag_type(git_tag* tag);
