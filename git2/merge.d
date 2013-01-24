module git2.merge;

import git2.oid;
import git2.types;

extern(C):

int git_merge_base(git_oid* _out, git_repository* repo, const(git_oid)* one, const(git_oid)* two);
int git_merge_base_many(git_oid* _out, git_repository* repo, const(git_oid)* input_array, size_t length);
