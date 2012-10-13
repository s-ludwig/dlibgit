module git2.common;

extern(C):

version(Windows)
{
    enum GIT_WIN32 = 1;
    enum GIT_PATH_LIST_SEPARATOR = ';';
}
else
{
    enum GIT_WIN32 = 0;
    enum GIT_PATH_LIST_SEPARATOR = ':';
}

enum GIT_PATH_MAX = 4096;

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
