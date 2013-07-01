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
import std.typecons;

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

    $(B Note): This is a refcounted type and can be
    safely copied by value. The underyling C handle will be
    released once the reference count reaches zero.
*/
struct GitOidShorten
{
    /// Default-construction is disabled
    @disable this();

    /**
        Create a new OID shortener. $(D length) is the minimum length
        which will be used to shorted the OIDs, even if a shorter
        length is possible to unique identify all OIDs.
    */
    this(size_t length)
    {
        enforceEx!GitException(length <= GitOid.MaxHexSize,
                               format("Error: Minimum hex length cannot be larger than '%s' (GitOid.MaxHexSize), it is '%s'", GitOid.MaxHexSize, length));

        _data = Data(length);
        _minLength = length;
    }

    ///
    unittest
    {
        auto oidShort = GitOidShorten(10);
        assert(oidShort.minLength == 10);

        // cannot be larger than MaxHexSize
        assertThrown!GitException(GitOidShorten(GitOid.MaxHexSize + 1));
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

        auto result = git_oid_shorten_add(_data._payload, hex.ptr);
        require(result >= 0);
        _minLength = result;
    }

    ///
    unittest
    {
        auto sh = GitOidShorten(5);
        assert(sh.minLength == 5);

        sh.add("1234000000000000000000000000000000000000");
        assert(sh.minLength == 5);

        sh.add("1234500000000000000000000000000000000000");
        assert(sh.minLength == 5);

        // introduce conflicting oid which requires a
        // larger length for unique identification in the set
        sh.add("1234560000000000000000000000000000000000");
        assert(sh.minLength == 6);
    }

    ///
    unittest
    {
        // adding a shortened hex is disallowed
        auto sh = GitOidShorten(5);
        assertThrown!GitException(sh.add("1234"));

        // default construction is disabled
        static assert(!__traits(compiles, GitOidShorten() ));
    }

    /** Return the current minimum length to uniquely identify the stored OIDs. */
    @property size_t minLength() { return _minLength; }

private:

    /** Payload for the $(D git_oid_shorten object) which should be refcounted. */
    struct Payload
    {
        this(size_t length)
        {
            _payload = enforce(git_oid_shorten_new(length), "Error: Out of memory.");
        }

        ~this()
        {
            // printf("-- dtor\n");

            if (_payload !is null)
            {
                git_oid_shorten_free(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        git_oid_shorten* _payload;
    }

    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;

    size_t _minLength;
}
