module git2.common;

import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

enum 
{
    GIT_CAP_THREADS = 1,
    GIT_CAP_HTTPS = 2
}

struct git_strarray 
{
    char** strings;
    size_t count;
}

int git_libgit2_capabilities();
void git_libgit2_version(int* major, int* minor, int* rev);
int git_strarray_copy(git_strarray* tgt, const(git_strarray)* src);
void git_strarray_free(git_strarray* array);
