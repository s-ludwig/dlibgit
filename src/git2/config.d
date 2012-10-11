module git2.config;

import git2.types;
import mingw.include.stdint;
import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

enum git_cvar_t
{
    GIT_CVAR_FALSE = 0,
    GIT_CVAR_TRUE = 1,
    GIT_CVAR_INT32 = 2,
    GIT_CVAR_STRING = 3
}

struct git_config_file 
{
    git_config* cfg;
    int function(git_config_file*) open;
    int function(git_config_file*, const(char)*, const(char)**) get;
    int function(git_config_file*, const(char)*, const(char)*, int function(const(char)*, void*), void*) get_multivar;
    int function(git_config_file*, const(char)*, const(char)*) set;
    int function(git_config_file*, const(char)*, const(char)*, const(char)*) set_multivar;
    int function(git_config_file*, const(char)*) del;
    int function(git_config_file*, const(char)*, int function(const(char)*, const(char)*, void*), void*) _foreach;
    void function(git_config_file*) free;
}

struct git_cvar_map 
{
    git_cvar_t cvar_type;
    const(char)* str_match;
    int map_value;
}

int git_config_add_file(git_config* cfg, git_config_file* file, int priority);
int git_config_add_file_ondisk(git_config* cfg, const(char)* path, int priority);
int git_config_delete(git_config* cfg, const(char)* name);
int git_config_file__ondisk(git_config_file** _out, const(char)* path);
int git_config_find_global(char* global_config_path, size_t length);
int git_config_find_system(char* system_config_path, size_t length);
int git_config_foreach(git_config* cfg, int function(const(char)*, const(char)*, void*) callback, void* payload);
int git_config_foreach_match(git_config* cfg, const(char)* regexp, int function(const(char)*, const(char)*, void*) callback, void* payload);
void git_config_free(git_config* cfg);
int git_config_get_bool(int* _out, git_config* cfg, const(char)* name);
int git_config_get_int32(int32_t* _out, git_config* cfg, const(char)* name);
int git_config_get_int64(int64_t* _out, git_config* cfg, const(char)* name);
int git_config_get_mapped(int* _out, git_config* cfg, const(char)* name, git_cvar_map* maps, size_t map_n);
int git_config_get_multivar(git_config* cfg, const(char)* name, const(char)* regexp, int function(const(char)*, void*) fn, void* data);
int git_config_get_string(const(char)** _out, git_config* cfg, const(char)* name);
int git_config_new(git_config** _out);
int git_config_open_default(git_config** _out);
int git_config_open_ondisk(git_config** cfg, const(char)* path);
int git_config_set_bool(git_config* cfg, const(char)* name, int value);
int git_config_set_int32(git_config* cfg, const(char)* name, int32_t value);
int git_config_set_int64(git_config* cfg, const(char)* name, int64_t value);
int git_config_set_multivar(git_config* cfg, const(char)* name, const(char)* regexp, const(char)* value);
int git_config_set_string(git_config* cfg, const(char)* name, const(char)* value);
