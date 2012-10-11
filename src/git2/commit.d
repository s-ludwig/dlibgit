module git2.commit;

import git2._object;
import git2.oid;
import git2.types;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

/** GIT_INLINE */
void git_commit_free(git_commit* commit)
{
    git_object_free(cast(git_object *) commit);
}

/** GIT_INLINE */
int git_commit_lookup(git_commit** commit, git_repository* repo, const(git_oid)* id)
{
    return git_object_lookup(cast(git_object **)commit, repo, id, git_otype.GIT_OBJ_COMMIT);
}

/** GIT_INLINE */
int git_commit_lookup_prefix(git_commit** commit, git_repository* repo, const(git_oid)* id, size_t len)
{
    return git_object_lookup_prefix(cast(git_object **)commit, repo, id, len, git_otype.GIT_OBJ_COMMIT);
}

const(git_signature)* git_commit_author(git_commit* commit);
const(git_signature)* git_commit_committer(git_commit* commit);
int git_commit_create(git_oid* oid, git_repository* repo, const(char)* update_ref, const(git_signature)* author, const(git_signature)* committer, const(char)* message_encoding, const(char)* message, const(git_tree)* tree, int parent_count, const(git_commit)** parents);
int git_commit_create_v(git_oid* oid, git_repository* repo, const(char)* update_ref, const(git_signature)* author, const(git_signature)* committer, const(char)* message_encoding, const(char)* message, const(git_tree)* tree, int parent_count, ...);
const(git_oid)* git_commit_id(git_commit* commit);
const(char)* git_commit_message(git_commit* commit);
const(char)* git_commit_message_encoding(git_commit* commit);
int git_commit_nth_gen_ancestor(git_commit** ancestor, const(git_commit)* commit, uint n);
int git_commit_parent(git_commit** parent, git_commit* commit, uint n);
const(git_oid)* git_commit_parent_oid(git_commit* commit, uint n);
uint git_commit_parentcount(git_commit* commit);
git_time_t git_commit_time(git_commit* commit);
int git_commit_time_offset(git_commit* commit);
int git_commit_tree(git_tree** tree_out, git_commit* commit);
const(git_oid)* git_commit_tree_oid(git_commit* commit);
