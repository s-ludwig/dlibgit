module git2.reflog;

import git2.oid;
import git2.types;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

int git_reflog_append(git_reflog* reflog, const(git_oid)* new_oid, const(git_signature)* committer, const(char)* msg);
int git_reflog_delete(git_reference* _ref);
int git_reflog_drop(git_reflog* reflog, uint idx, int rewrite_previous_entry);
const(git_reflog_entry)* git_reflog_entry_byindex(git_reflog* reflog, size_t idx);
git_signature* git_reflog_entry_committer(const(git_reflog_entry)* entry);
char* git_reflog_entry_msg(const(git_reflog_entry)* entry);
const(git_oid)* git_reflog_entry_oidnew(const(git_reflog_entry)* entry);
const(git_oid)* git_reflog_entry_oidold(const(git_reflog_entry)* entry);
uint git_reflog_entrycount(git_reflog* reflog);
void git_reflog_free(git_reflog* reflog);
int git_reflog_read(git_reflog** reflog, git_reference* _ref);
int git_reflog_rename(git_reference* _ref, const(char)* new_name);
int git_reflog_write(git_reflog* reflog);
