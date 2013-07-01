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
        create a GitOid object.

        $(D hex) must be at least the size of $(D MinHexSize),
        but not larger than $(D MaxHexSize).
    */
    this(const(char)[] hex)
    {
        assert(hex.length >= MinHexSize && hex.length <= MaxHexSize);
        require(git_oid_fromstrn(&_oid, hex.ptr, hex.length) == 0);
    }

    ///
    unittest
    {
        // note: don't use an enum due to http://d.puremagic.com/issues/show_bug.cgi?id=10516
        const srcHex = "49322bb17d3acc9146f98c97d078513228bbf3c0";
        const oid = GitOid(srcHex);

        char[MaxHexSize] tgtHex;
        git_oid_fmt(tgtHex.ptr, &oid._oid);

        assert(tgtHex == srcHex);
    }

    ///
    unittest
    {
        // can convert from a partial string
        const srcHex = "4932";
        const oid = GitOid(srcHex);

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
        assertThrown!AssertError(GitOid(smallHex));

        /// cannot convert from a string bigger than MinHexSize
        const bigHex = std.array.replicate("1", MaxHexSize + 1);
        assertThrown!AssertError(GitOid(bigHex));
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
        const oid = GitOid(hex);
        assert(oid.toHex == hex);
    }

    ///
    unittest
    {
        // convert partial hex to oid and back to hex
        const hex = "4932";
        const oid = GitOid(hex);
        assert(oid.toHex == "4932000000000000000000000000000000000000");
    }

private:
    git_oid _oid;
}

/**
    The OID shortener is used to process a list of OIDs
    in text form and return the shortest length that would
    uniquely identify all of them.
*/
struct GitOidShorten
{
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

    this(size_t length)
    {
        _git_oid_shorten = enforce(git_oid_shorten_new(length), "Error: Out of memory.");
    }

    //~ void add
    //~ int git_oid_shorten_add(git_oid_shorten *os, const(char)* text_id);

private:
    git_oid_shorten* _git_oid_shorten;
}

// todo: remove these once all are ported
extern (C):

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
