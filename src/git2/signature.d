module git2.signature;

import git2.types;

extern(C):

git_signature* git_signature_dup(const(git_signature)* sig);
void git_signature_free(git_signature* sig);
int git_signature_new(git_signature** sig_out, const(char)* name, const(char)* email, git_time_t time, int offset);
int git_signature_now(git_signature** sig_out, const(char)* name, const(char)* email);
