module git2.notes;

import git2.oid;
import git2.types;

extern(C):

struct git_note_data 
{
    git_oid blob_oid;
    git_oid annotated_object_oid;
}

int git_note_create(git_oid* _out, git_repository* repo, git_signature* author, git_signature* committer, const(char)* notes_ref, const(git_oid)* oid, const(char)* note);
int git_note_default_ref(const(char)** _out, git_repository* repo);
int git_note_foreach(git_repository* repo, const(char)* notes_ref, int function(git_note_data*, void*) note_cb, void* payload);
void git_note_free(git_note* note);
const(char)* git_note_message(git_note* note);
const(git_oid)* git_note_oid(git_note* note);
int git_note_read(git_note** note, git_repository* repo, const(char)* notes_ref, const(git_oid)* oid);
int git_note_remove(git_repository* repo, const(char)* notes_ref, git_signature* author, git_signature* committer, const(git_oid)* oid);
