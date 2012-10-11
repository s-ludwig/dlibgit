module git2.reset;

import git2.types;

extern(C):

int git_reset(git_repository* repo, git_object* target, git_reset_type reset_type);
