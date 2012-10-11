module git2.errors;

extern(C):

enum git_error_t
{
    GITERR_NOMEMORY = 0,
    GITERR_OS = 1,
    GITERR_INVALID = 2,
    GITERR_REFERENCE = 3,
    GITERR_ZLIB = 4,
    GITERR_REPOSITORY = 5,
    GITERR_CONFIG = 6,
    GITERR_REGEX = 7,
    GITERR_ODB = 8,
    GITERR_INDEX = 9,
    GITERR_OBJECT = 10,
    GITERR_NET = 11,
    GITERR_TAG = 12,
    GITERR_TREE = 13,
    GITERR_INDEXER = 14,
    GITERR_SSL = 15,
    GITERR_SUBMODULE = 16
}

enum 
{
    GIT_OK = 0,
    GIT_ERROR = -1,
    GIT_ENOTFOUND = -3,
    GIT_EEXISTS = -4,
    GIT_EAMBIGUOUS = -5,
    GIT_EBUFS = -6,
    GIT_EUSER = -7,
    GIT_EBAREREPO = -8,
    GIT_PASSTHROUGH = -30,
    GIT_ITEROVER = -31
}

struct git_error 
{
    char* message;
    int klass;
}

void giterr_clear();
const(git_error)* giterr_last();
void giterr_set_oom();
void giterr_set_str(int error_class, const(char)* _string);
