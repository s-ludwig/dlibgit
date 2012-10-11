module git2.oid;

import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

/** Size (in bytes) of a raw/binary oid */
enum GIT_OID_RAWSZ = 20;

/** Size (in bytes) of a hex formatted oid */
enum GIT_OID_HEXSZ = GIT_OID_RAWSZ * 2;

/** GIT_INLINE */
int git_oid_cmp(const(git_oid)* a, const(git_oid)* b)
{
	const(ubyte)* sha1 = a.id.ptr;
	const(ubyte)* sha2 = b.id.ptr;
	int i;

	for (i = 0; i < GIT_OID_RAWSZ; i++, sha1++, sha2++) {
		if (*sha1 != *sha2)
			return *sha1 - *sha2;
	}

	return 0;    
}

/** GIT_INLINE */
int git_oid_equal(const(git_oid)* a, const(git_oid)* b)
{
    return !git_oid_cmp(a, b);
}

alias _git_oid git_oid;

struct _git_oid 
{
    ubyte[20] id;
}

struct git_oid_shorten { }

char* git_oid_allocfmt(const(git_oid)* oid);
void git_oid_cpy(git_oid* _out, const(git_oid)* src);
void git_oid_fmt(char* str, const(git_oid)* oid);
void git_oid_fromraw(git_oid* _out, const(ubyte)* raw);
int git_oid_fromstr(git_oid* _out, const(char)* str);
int git_oid_fromstrn(git_oid* _out, const(char)* str, size_t length);
int git_oid_iszero(const(git_oid)* a);
int git_oid_ncmp(const(git_oid)* a, const(git_oid)* b, size_t len);
void git_oid_pathfmt(char* str, const(git_oid)* oid);
int git_oid_shorten_add(git_oid_shorten* os, const(char)* text_oid);
void git_oid_shorten_free(git_oid_shorten* os);
git_oid_shorten* git_oid_shorten_new(size_t min_length);
int git_oid_streq(const(git_oid)* a, const(char)* str);
char* git_oid_tostr(char* _out, size_t n, const(git_oid)* oid);
