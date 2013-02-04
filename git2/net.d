module git2.net;

import git2.oid;
import git2.types;
import std.bitmanip;

extern(C):

enum GIT_DEFAULT_PORT = "9418";

enum git_direction {
	FETCH = 0,
	PUSH  = 1
}

alias int function(git_remote_head*, void*) git_headlist_cb;

struct git_remote_head 
{
    mixin(bitfields!(
        int, "local", 1,
        int, "", 31
    ));
    git_oid oid;
    git_oid loid;
    char* name;
}
