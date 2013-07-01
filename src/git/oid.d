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

import git.exception;
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
        Create a new OID shortener. $(D minLength) is the minimum length
        which will be used to shorted the OIDs, even if a shorter
        length is possible to unique identify all OIDs.
    */
    this(size_t minLength)
    {
        _git_oid_shorten = enforce(git_oid_shorten_new(minLength), "Error: Out of memory.");
        _minLength = minLength;
    }

    /**
        Add a new hex OID to the set of shortened OIDs and store
        the minimal length to uniquely identify all the OIDs in
        the set. This length can then be retrieved by calling $(D minLength).

        $(B Note:) The hex OID must be a 40-char hexadecimal string. Calling
        $(D add) with a shorter OID will thrown a GitOid exception.

        For performance reasons, there is a hard-limit of how many
        OIDs can be added to a single set - around ~22000, assuming
        a mostly randomized distribution.

        Attempting to go over this limit will throw a $(D GitException).
    */
    void add(const(char)[] hex)
    {
        enforceEx!GitException(hex.length == GitOid.MaxHexSize,
                               format("Error: Hex string size must be equal to '%s' (GitOid.MaxHexSize), not '%s'", GitOid.MaxHexSize, hex.length));

        auto result = git_oid_shorten_add(_git_oid_shorten, hex.ptr);
        require(result >= 0);
        _minLength = result;
    }

    ~this()
    {
        git_oid_shorten_free(_git_oid_shorten);
    }

    /** Return the current minimum length to uniquely identify the stored OIDs. */
    @property size_t minLength() { return _minLength; }

private:
    git_oid_shorten* _git_oid_shorten;
    size_t _minLength;
}
