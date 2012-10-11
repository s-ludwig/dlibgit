module git2.revwalk;

import git2.oid;
import git2.types;

extern(C):

void git_revwalk_free(git_revwalk* walk);
int git_revwalk_hide(git_revwalk* walk, const(git_oid)* oid);
int git_revwalk_hide_glob(git_revwalk* walk, const(char)* glob);
int git_revwalk_hide_head(git_revwalk* walk);
int git_revwalk_hide_ref(git_revwalk* walk, const(char)* refname);
int git_revwalk_new(git_revwalk** walker, git_repository* repo);
int git_revwalk_next(git_oid* oid, git_revwalk* walk);
int git_revwalk_push(git_revwalk* walk, const(git_oid)* oid);
int git_revwalk_push_glob(git_revwalk* walk, const(char)* glob);
int git_revwalk_push_head(git_revwalk* walk);
int git_revwalk_push_ref(git_revwalk* walk, const(char)* refname);
git_repository* git_revwalk_repository(git_revwalk* walk);
void git_revwalk_reset(git_revwalk* walker);
void git_revwalk_sorting(git_revwalk* walk, uint sort_mode);
