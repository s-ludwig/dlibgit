module git2.tree;

import git2._object;
import git2.oid;
import git2.types;

extern(C):

/** GIT_INLINE */
void git_tree_free(git_tree* tree)
{
    git_object_free(cast(git_object *) tree);
}

/** GIT_INLINE */
int git_tree_lookup(git_tree** tree, git_repository* repo, const(git_oid)* id)
{
	return git_object_lookup(cast(git_object**)tree, repo, id, git_otype.GIT_OBJ_TREE);
}

/** GIT_INLINE */
int git_tree_lookup_prefix(git_tree** tree, git_repository* repo, const(git_oid)* id, size_t len)
{
	return git_object_lookup_prefix(cast(git_object**)tree, repo, id, len, git_otype.GIT_OBJ_TREE);
}

enum git_treewalk_mode
{
    GIT_TREEWALK_PRE = 0,
    GIT_TREEWALK_POST = 1
}

alias int function(const(char)*, const(git_tree_entry)*, void*) git_treewalk_cb;

int git_tree_create_fromindex(git_oid* oid, git_index* index);
const(git_tree_entry)* git_tree_entry_byindex(git_tree* tree, size_t idx);
const(git_tree_entry)* git_tree_entry_byname(git_tree* tree, const(char)* filename);
const(git_tree_entry)* git_tree_entry_byoid(git_tree* tree, const(git_oid)* oid);
int git_tree_entry_bypath(git_tree_entry** entry, git_tree* root, const(char)* path);
git_tree_entry* git_tree_entry_dup(const(git_tree_entry)* entry);
git_filemode_t git_tree_entry_filemode(const(git_tree_entry)* entry);
void git_tree_entry_free(git_tree_entry* entry);
const(git_oid)* git_tree_entry_id(const(git_tree_entry)* entry);
const(char)* git_tree_entry_name(const(git_tree_entry)* entry);
int git_tree_entry_to_object(git_object** object_out, git_repository* repo, const(git_tree_entry)* entry);
git_otype git_tree_entry_type(const(git_tree_entry)* entry);
uint git_tree_entrycount(git_tree* tree);
const(git_oid)* git_tree_id(git_tree* tree);
int git_tree_walk(git_tree* tree, git_treewalk_cb callback, int mode, void* payload);
void git_treebuilder_clear(git_treebuilder* bld);
int git_treebuilder_create(git_treebuilder** builder_p, const(git_tree)* source);
void git_treebuilder_filter(git_treebuilder* bld, int function(const(git_tree_entry)*, void*) filter, void* payload);
void git_treebuilder_free(git_treebuilder* bld);
const(git_tree_entry)* git_treebuilder_get(git_treebuilder* bld, const(char)* filename);
int git_treebuilder_insert(const(git_tree_entry)** entry_out, git_treebuilder* bld, const(char)* filename, const(git_oid)* id, git_filemode_t filemode);
int git_treebuilder_remove(git_treebuilder* bld, const(char)* filename);
int git_treebuilder_write(git_oid* oid, git_repository* repo, git_treebuilder* bld);
