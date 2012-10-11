module git2.branch;

import git2.types;

extern(C):

int git_branch_create(git_reference** branch_out, git_repository* repo, const(char)* branch_name, const(git_object)* target, int force);
int git_branch_delete(git_reference* branch);
int git_branch_foreach(git_repository* repo, uint list_flags, int function(const(char)*, git_branch_t, void*) branch_cb, void* payload);
int git_branch_lookup(git_reference** branch_out, git_repository* repo, const(char)* branch_name, git_branch_t branch_type);
int git_branch_move(git_reference* branch, const(char)* new_branch_name, int force);
int git_branch_tracking(git_reference** tracking_out, git_reference* branch);
