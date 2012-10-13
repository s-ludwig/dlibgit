module git2.refspec;

import git2.types;

extern(C):

const(char)* git_refspec_dst(const(git_refspec)* refspec);
int git_refspec_force(const(git_refspec)* refspec);
const(char)* git_refspec_src(const(git_refspec)* refspec);
int git_refspec_src_matches(const(git_refspec)* refspec, const(char)* refname);
int git_refspec_transform(char* _out, size_t outlen, const(git_refspec)* spec, const(char)* name);
