module git2.revparse;

import git2.types;

extern(C):

int git_revparse_single(git_object** _out, git_repository* repo, const(char)* spec);
