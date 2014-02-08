/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.credentials;

import std.conv;
import std.exception;
import std.string;
import std.typecons;

import git2.transport;

import git.exception;
import git.util;

version (GIT_SSH)
{
    static assert(0, "dlibgit does not support SSH yet.");
}

/* The base structure for all credential types. */
struct GitCred
{
    // internal
    private this(git_cred* cred)
    {
        _data = Data(cred);
    }

    /**
        Return the actual credential type of this credential.
        Use the $(D get) template to cast this type to the
        type tagged as $(D credType).
    */
    @property GitCredType credType()
    {
        return cast(GitCredType)_data._payload.credtype;
    }

    /** Throw if the target credential type is not equal to credType that's stored. */
    void verifyTypeMatch(GitCredType target)
    {
        enforceEx!GitException(credType == target,
                               format("Tried to cast GitCred of type '%s' to type '%s'",
                                      credType, target));
    }

    /**
        Cast this credential to the structure type matching
        the $(D cred) enum tag.

        If the underlying type does not match the target type,
        a $(D GitException) is thrown.
    */
    auto get(GitCredType cred)()
    {
        return get!(_credToType!cred);
    }

    /**
        Cast this credential to a specific credential type $(D T).

        If the underlying type does not match the target type,
        a $(D GitException) is thrown.
    */
    T get(T)() if (isGitCredential!T)
    {
        verifyTypeMatch(T.credType);
        return getImpl!T;
    }

package:
    /**
     * The internal libgit2 handle for this object.
     *
     * Care should be taken not to escape the reference outside a scope where
     * a GitCred encapsulating the handle is kept alive.
     */
    @property git_cred* cHandle()
    {
        return _data._payload;
    }

private:

    T getImpl(T : GitCred_PlainText)()
    {
        auto cred = cast(T.c_cred_struct*)_data._payload;

        T result;
        result.parent = this;
        result.username = to!string(cred.username);
        result.password = to!string(cred.password);
        return result;
    }

    version (GIT_SSH)
    {
        static assert(0, "dlibgit does not support SSH yet.");

        T getImpl(T : GitCred_KeyFilePassPhrase)()
        {
            auto cred = cast(T.c_cred_struct*)_data._payload;

            T result;
            result.parent = this;
            result.publickey = to!string(cred.publickey);
            result.privatekey = to!string(cred.privatekey);
            result.passphrase = to!string(cred.passphrase);
            return result;
        }

        T getImpl(T : GitCred_PublicKey)()
        {
            auto cred = cast(T.c_cred_struct*)_data._payload;

            T result;
            result.parent = this;
            result.publickey = cred.publickey[0 .. cred.publickey_len];
            result.sign_callback = cred.sign_callback;
            result.sign_data = cred.sign_data;
            return result;
        }
    }

    /** Payload for the $(D git_cred) object which should be refcounted. */
    struct Payload
    {
        this(git_cred* payload)
        {
            _payload = payload;
        }

        ~this()
        {
            //~ writefln("- %s", __FUNCTION__);

            if (_payload !is null)
            {
                _payload.free(_payload);
                _payload = null;
            }
        }

        /// Should never perform copy
        @disable this(this);

        /// Should never perform assign
        @disable void opAssign(typeof(this));

        git_cred* _payload;
    }

    alias RefCounted!(Payload, RefCountedAutoInitialize.no) Data;
    Data _data;
}

///
enum GitCredType
{
    ///
	plaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,

    ///
	passphrase = GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE,

    ///
	publickey = GIT_CREDTYPE_SSH_PUBLICKEY,
}

/* A plaintext username and password. */
struct GitCred_PlainText
{
    ///
    enum credType = GitCredType.plaintext;

    ///
	GitCred parent;

    ///
	string username;

    ///
	string password;

    private alias c_cred_struct = git_cred_userpass_plaintext;
}

version (GIT_SSH)
{
    static assert(0, "dlibgit does not support SSH yet.");

    /* A ssh key file and passphrase. */
    struct GitCred_KeyFilePassPhrase
    {
        ///
        enum credType = GitCredType.passphrase;

        ///
        GitCred parent;

        ///
        string publicKey;

        ///
        string privateKey;

        ///
        string passPhrase;

        private alias c_cred_struct = git_cred_ssh_keyfile_passphrase;
    }

    /* A ssh public key and authentication callback. */
    struct GitCred_PublicKey
    {
        ///
        enum credType = GitCredType.publickey;

        ///
        GitCred parent;

        ///
        ubyte[] publicKey;

        ///
        void* signCallback;

        ///
        void* signData;

        private alias c_cred_struct = git_cred_ssh_publickey;
    }
}

/** Check if type $(D T) is one of the supported git credential types. */
template isGitCredential(T)
{
    version (GIT_SSH)
    {
        static assert(0, "dlibgit does not support SSH yet.");

        enum bool isGitCredential = is(T == GitCred_PlainText) ||
                                    is(T == GitCred_KeyFilePassPhrase) ||
                                    is(T == GitCred_PublicKey);
    }
    else
    {
        enum bool isGitCredential = is(T == GitCred_PlainText);
    }
}

// helper
private template _credToType(GitCredType credType)
{
    static if (credType == GitCredType.plaintext)
        alias _credToType = GitCred_PlainText;
    else
    version (GIT_SSH)
    {
        static assert(0, "dlibgit does not support SSH yet.");

        static if (credType == GitCredType.passphrase)
            alias _credToType = GitCred_KeyFilePassPhrase;
        else
        static if (credType == GitCredType.publickey)
            alias _credToType = GitCred_PublicKey;
        else
        static assert(0);
    }
    else
    static assert(0);
}

/**
    Creates a new plain-text username and password credential object.
    The supplied credential parameter will be internally duplicated.
*/
GitCred getCredPlainText(string username, string password)
{
    git_cred* _git_cred;
    require(git_cred_userpass_plaintext_new(&_git_cred, username.gitStr, password.gitStr) == 0);
    return GitCred(_git_cred);
}

///
unittest
{
    auto cred = getCredPlainText("user", "pass");

    switch (cred.credType) with (GitCredType)
    {
        case plaintext:
        {
            version (GIT_SSH)
            {
                static assert(0, "dlibgit does not support SSH yet.");

                // throw when trying to cast to an inappropriate type
                assertThrown!GitException(cred.get!passphrase);

                // ditto
                assertThrown!GitException(cred.get!GitCred_KeyFilePassPhrase);
            }

            // use enum for the get template
            auto cred1 = cred.get!plaintext;
            assert(cred1.username == "user");
            assert(cred1.password == "pass");

            // or use a type
            auto cred2 = cred.get!GitCred_PlainText;
            assert(cred2.username == "user");
            assert(cred2.password == "pass");

            break;
        }

        default: assert(0, text(cred.credType));
    }
}

version (GIT_SSH)
{
    static assert(0, "dlibgit does not support SSH yet.");

    /**
        Creates a new ssh key file and passphrase credential object.
        The supplied credential parameter will be internally duplicated.

        Params:

        - $(D publicKey): The path to the public key of the credential.
        - $(D privateKey): The path to the private key of the credential.
        - $(D passPhrase): The passphrase of the credential.
    */
    GitCred getCredKeyFilePassPhrase(string publicKey, string privateKey, string passPhrase)
    {
        git_cred* _git_cred;
        require(git_cred_ssh_keyfile_passphrase_new(&_git_cred, publicKey.gitStr, privateKey.gitStr, passPhrase.gitStr) == 0);
        return GitCred(_git_cred);
    }

    ///
    unittest
    {
        auto cred = getCredKeyFilePassPhrase("public", "private", "passphrase");

        switch (cred.credType) with (GitCredType)
        {
            case passphrase:
            {
                // throw when trying to cast to an inappropriate type
                assertThrown!GitException(cred.get!plaintext);

                // ditto
                assertThrown!GitException(cred.get!GitCred_PlainText);

                // use enum for the get template
                auto cred1 = cred.get!passphrase;
                assert(cred1.publicKey == "public");
                assert(cred1.privateKey == "private");
                assert(cred1.passPhrase == "passphrase");

                // or use a type
                auto cred2 = cred.get!GitCred_KeyFilePassPhrase;
                assert(cred2.publicKey == "public");
                assert(cred2.privateKey == "private");
                assert(cred2.passPhrase == "passphrase");

                break;
            }

            default: assert(0, text(cred.credType));
        }
    }

    /**
        Creates a new ssh public key credential object.
        The supplied credential parameter will be internally duplicated.

        Params:

        - $(D publicKey): The bytes of the public key.
        - $(D signCallback): The callback method for authenticating.
        - $(D signData): The abstract data sent to the $(D signCallback) method.
    */
    GitCred getCredPublicKey(ubyte[] publicKey, void* signCallback, void* signData)
    {
        git_cred* _git_cred;
        require(git_cred_ssh_publickey_new(&_git_cred, publicKey.ptr, publicKey.length, signCallback, signData) == 0);
        return GitCred(_git_cred);
    }

    ///
    unittest
    {
        auto cred = getCredPublicKey([], null, null);

        switch (cred.credType) with (GitCredType)
        {
            case publickey:
            {
                // throw when trying to cast to an inappropriate type
                assertThrown!GitException(cred.get!plaintext);

                // ditto
                assertThrown!GitException(cred.get!GitCred_PlainText);

                // use enum for the get template
                auto cred1 = cred.get!publickey;
                assert(cred1.publicKey == []);
                assert(cred1.signCallback is null);
                assert(cred1.signData is null);

                // or use a type
                auto cred2 = cred.get!GitCred_PublicKey;
                assert(cred2.publicKey == []);
                assert(cred2.signCallback is null);
                assert(cred2.signData is null);

                break;
            }

            default: assert(0, text(cred.credType));
        }
    }
}

alias GitCredAcquireDelegate = GitCred delegate(
    in char[] url,
    in char[] usernameFromURL,
    uint allowedTypes);
