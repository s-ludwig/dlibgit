/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.oid;

import core.exception;

import std.algorithm;
import std.exception;
import std.conv;
import std.range;
import std.stdio;
import std.string;

import git.c.common;
import git.c.oid;
import git.c.types;

import git.util;

/**
    The unique ID of any Git object, whether it's a commit,
    tree, blob, tag, etc.
*/
struct GitOid
{
    /** Size (in bytes) of a raw/binary oid */
    enum BinarySize = GIT_OID_RAWSZ;

    /** Minimum length (in number of hex characters,
     * i.e. packets of 4 bits) of an oid prefix */
    enum MinHexSize = GIT_OID_MINPREFIXLEN;

    /** Size (in bytes) of a hex formatted oid */
    enum MaxHexSize = GIT_OID_HEXSZ;

    /**
        Parse a full or partial hex-formatted object ID and
        return a GitOid object.

        $(D input) must be at least the size of $(D MinHexSize),
        but not larger than $(D MaxHexSize).
    */
    static GitOid fromHex(const(char)[] input)
    {
        assert(input.length >= MinHexSize && input.length <= MaxHexSize);
        GitOid result;
        require(git_oid_fromstrn(&result._oid, input.ptr, input.length) == 0);
        return result;
    }

    ///
    unittest
    {
        // note: don't use an enum due to http://d.puremagic.com/issues/show_bug.cgi?id=10516
        const srcHex = "49322bb17d3acc9146f98c97d078513228bbf3c0";
        const oid = GitOid.fromHex(srcHex);

        char[MaxHexSize] tgtHex;
        git_oid_fmt(tgtHex.ptr, &oid._oid);

        assert(tgtHex == srcHex);
    }

    ///
    unittest
    {
        // can convert from a partial string
        const srcHex = "4932";
        const oid = GitOid.fromHex(srcHex);

        char[MaxHexSize] tgtHex;
        git_oid_fmt(tgtHex.ptr, &oid._oid);

        assert(tgtHex[0 .. 4] == srcHex);
        assert(tgtHex[4 .. $].count('0') == tgtHex.length - 4);
    }

    ///
    unittest
    {
        /// cannot convert from a partial string smaller than MinHexSize
        const smallHex = "493";
        assertThrown!AssertError(GitOid.fromHex(smallHex));

        /// cannot convert from a string bigger than MinHexSize
        const bigHex = std.array.replicate("1", MaxHexSize + 1);
        assertThrown!AssertError(GitOid.fromHex(bigHex));
    }

    /**
        Convert this GitOid into a hex string.

        $(B Note): If this oid has been constructed with a partial
        hex string, $(D toHex) will still return a hex string of size
        $(D MaxHexSize) but with padded zeros.
    */
    string toHex() const
    {
        auto buffer = new char[](MaxHexSize);
        git_oid_nfmt(buffer.ptr, MaxHexSize, &_oid);
        return assumeUnique(buffer);
    }

    ///
    unittest
    {
        // convert hex to oid and back to hex
        const hex = "49322bb17d3acc9146f98c97d078513228bbf3c0";
        const oid = GitOid.fromHex(hex);
        assert(oid.toHex == hex);
    }

    ///
    unittest
    {
        // convert partial hex to oid and back to hex
        const hex = "4932";
        const oid = GitOid.fromHex(hex);
        assert(oid.toHex == "4932000000000000000000000000000000000000");
    }

private:
    git_oid _oid;
}

// todo: remove these once all are ported
extern (C):

//~ /**
 //~ * Format a git_oid into a hex string.
 //~ *
 //~ * @param out_ output hex string; must be pointing at the start of
 //~ *		the hex sequence and have at least the number of bytes
 //~ *		needed for an oid encoded in hex (40 bytes). Only the
 //~ *		oid digits are written; a '\\0' terminator must be added
 //~ *		by the caller if it is required.
 //~ * @param id oid structure to format.
 //~ */
//~ void git_oid_fmt(char *out_, const(git_oid)* id);

/**
 * Format a git_oid into a partial hex string.
 *
 * @param out_ output hex string; you say how many bytes to write.
 *		If the number of bytes is > GIT_OID_HEXSZ, extra bytes
 *		will be zeroed; if not, a '\0' terminator is NOT added.
 * @param n number of characters to write into out_ string
 * @param id oid structure to format.
 */
void git_oid_nfmt(char *out_, size_t n, const(git_oid)* id);

/**
 * Format a git_oid into a loose-object path string.
 *
 * The resulting string is "aa/...", where "aa" is the first two
 * hex digits of the oid and "..." is the remaining 38 digits.
 *
 * @param out_ output hex string; must be pointing at the start of
 *		the hex sequence and have at least the number of bytes
 *		needed for an oid encoded in hex (41 bytes). Only the
 *		oid digits are written; a '\\0' terminator must be added
 *		by the caller if it is required.
 * @param id oid structure to format.
 */
void git_oid_pathfmt(char *out_, const(git_oid)* id);

/**
 * Format a git_oid into a newly allocated c-string.
 *
 * @param id the oid structure to format
 * @return the c-string; NULL if memory is exhausted. Caller must
 *			deallocate the string with git__free().
 */
char* git_oid_allocfmt(const(git_oid)* id);

/**
 * Format a git_oid into a buffer as a hex format c-string.
 *
 * If the buffer is smaller than GIT_OID_HEXSZ+1, then the resulting
 * oid c-string will be truncated to n-1 characters (but will still be
 * NUL-byte terminated).
 *
 * If there are any input parameter errors (out_ == NULL, n == 0, oid ==
 * NULL), then a pointer to an empty string is returned, so that the
 * return value can always be printed.
 *
 * @param out_ the buffer into which the oid string is output.
 * @param n the size of the out_ buffer.
 * @param id the oid structure to format.
 * @return the out_ buffer pointer, assuming no input parameter
 *			errors, otherwise a pointer to an empty string.
 */
char * git_oid_tostr(char *out_, size_t n, const(git_oid)* id);

/**
 * Copy an oid from one structure to another.
 *
 * @param out_ oid structure the result is written into.
 * @param src oid structure to copy from.
 */
void git_oid_cpy(git_oid *out_, const(git_oid)* src);

/**
 * Compare two oid structures.
 *
 * @param a first oid structure.
 * @param b second oid structure.
 * @return <0, 0, >0 if a < b, a == b, a > b.
 */
int git_oid_cmp(const(git_oid)* a, const(git_oid)* b);

/**
 * Compare two oid structures for equality
 *
 * @param a first oid structure.
 * @param b second oid structure.
 * @return true if equal, false otherwise
 */
int git_oid_equal(const(git_oid)* a, const(git_oid)* b);

/**
 * Compare the first 'len' hexadecimal characters (packets of 4 bits)
 * of two oid structures.
 *
 * @param a first oid structure.
 * @param b second oid structure.
 * @param len the number of hex chars to compare
 * @return 0 in case of a match
 */
int git_oid_ncmp(const(git_oid)* a, const(git_oid)* b, size_t len);

/**
 * Check if an oid equals an hex formatted object id.
 *
 * @param id oid structure.
 * @param str input hex string of an object id.
 * @return GIT_ENOTOID if str is not a valid hex string,
 * 0 in case of a match, GIT_ERROR otherwise.
 */
int git_oid_streq(const(git_oid)* id, const(char)* str);

/**
 * Compare an oid to an hex formatted object id.
 *
 * @param id oid structure.
 * @param str input hex string of an object id.
 * @return -1 if str is not valid, <0 if id sorts before str,
 *         0 if id matches str, >0 if id sorts after str.
 */
int git_oid_strcmp(const(git_oid)* id, const(char)* str);

/**
 * Check is an oid is all zeros.
 *
 * @return 1 if all zeros, 0 otherwise.
 */
int git_oid_iszero(const(git_oid)* id);

/**
 * OID Shortener object
 */
//~ struct git_oid_shorten;

/**
 * Create a new OID shortener.
 *
 * The OID shortener is used to process a list of OIDs
 * in text form and return the shortest length that would
 * uniquely identify all of them.
 *
 * E.g. look at the result of `git log --abbrev`.
 *
 * @param min_length The minimal length for all identifiers,
 *		which will be used even if shorter OIDs would still
 *		be unique.
 *	@return a `git_oid_shorten` instance, NULL if OOM
 */
git_oid_shorten * git_oid_shorten_new(size_t min_length);

/**
 * Add a new OID to set of shortened OIDs and calculate
 * the minimal length to uniquely identify all the OIDs in
 * the set.
 *
 * The OID is expected to be a 40-char hexadecimal string.
 * The OID is owned by the user and will not be modified
 * or freed.
 *
 * For performance reasons, there is a hard-limit of how many
 * OIDs can be added to a single set (around ~22000, assuming
 * a mostly randomized distribution), which should be enough
 * for any kind of program, and keeps the algorithm fast and
 * memory-efficient.
 *
 * Attempting to add more than those OIDs will result in a
 * GIT_ENOMEM error
 *
 * @param os a `git_oid_shorten` instance
 * @param text_id an OID in text form
 * @return the minimal length to uniquely identify all OIDs
 *		added so far to the set; or an error code (<0) if an
 *		error occurs.
 */
int git_oid_shorten_add(git_oid_shorten *os, const(char)* text_id);

/**
 * Free an OID shortener instance
 *
 * @param os a `git_oid_shorten` instance
 */
void git_oid_shorten_free(git_oid_shorten *os);
