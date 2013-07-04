/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module git.transport;

import std.conv;
import std.exception;
import std.stdio;
import std.string;
import std.typecons;

import git.c.clone;

import git.checkout;
import git.exception;
import git.repository;
import git.types;
import git.util;

import git.c.indexer;
import git.c.net;
import git.c.transport;
import git.c.types;
import git.c.util;

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
    require(git_cred_userpass_plaintext_new(&_git_cred, username.toStringz, password.toStringz) == 0);
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
        require(git_cred_ssh_keyfile_passphrase_new(&_git_cred, publicKey.toStringz, privateKey.toStringz, passPhrase.toStringz) == 0);
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

//~ /**
 //~ * Signature of a function which acquires a credential object.
 //~ *
 //~ * @param cred The newly created credential object.
 //~ * @param url The resource for which we are demanding a credential.
 //~ * @param username_from_url The username that was embedded in a "user@host"
 //~ *                          remote url, or NULL if not included.
 //~ * @param allowed_types A bitmask stating which cred types are OK to return.
 //~ * @param payload The payload provided when specifying this callback.
 //~ * @return 0 for success or an error code for failure
 //~ */
//~ alias git_cred_acquire_cb = int function(
	//~ git_cred **cred,
	//~ const(char)* url,
	//~ const(char)* username_from_url,
	//~ uint allowed_types,
	//~ void *payload);

//~ /*
 //~ *** End interface for credentials acquisition ***
 //~ *** Begin base transport interface ***
 //~ */

//~ enum git_transport_flags_t {
	//~ GIT_TRANSPORTFLAGS_NONE = 0,
	//~ /* If the connection is secured with SSL/TLS, the authenticity
	 //~ * of the server certificate should not be verified. */
	//~ GIT_TRANSPORTFLAGS_NO_CHECK_CERT = 1
//~ } ;


//~ mixin _ExportEnumMembers!git_transport_flags_t;

//~ alias git_transport_message_cb = void function(const(char)* str, int len, void *data);

//~ struct git_transport
//~ {
	//~ uint version_ = GIT_TRANSPORT_VERSION;

	//~ /* Set progress and error callbacks */
	//~ int function(git_transport *transport,
		//~ git_transport_message_cb progress_cb,
		//~ git_transport_message_cb error_cb,
		//~ void *payload) set_callbacks;

	//~ /* Connect the transport to the remote repository, using the given
	 //~ * direction. */
	//~ int function(git_transport *transport,
		//~ const(char)* url,
		//~ git_cred_acquire_cb cred_acquire_cb,
		//~ void *cred_acquire_payload,
		//~ int direction,
		//~ int flags) connect;

	//~ /* This function may be called after a successful call to connect(). The
	 //~ * provided callback is invoked for each ref discovered on the remote
	 //~ * end. */
	//~ int function(git_transport *transport,
		//~ git_headlist_cb list_cb,
		//~ void *payload) ls;

	//~ /* Executes the push whose context is in the git_push object. */
	//~ int function(git_transport *transport, git_push *push) push;

	//~ /* This function may be called after a successful call to connect(), when
	 //~ * the direction is FETCH. The function performs a negotiation to calculate
	 //~ * the wants list for the fetch. */
	//~ int function(git_transport *transport,
		//~ git_repository *repo,
		//~ const(git_remote_head**) refs_,
		//~ size_t count) negotiate_fetch;

	//~ /* This function may be called after a successful call to negotiate_fetch(),
	 //~ * when the direction is FETCH. This function retrieves the pack file for
	 //~ * the fetch from the remote end. */
	//~ int function(git_transport *transport,
		//~ git_repository *repo,
		//~ git_transfer_progress *stats,
		//~ git_transfer_progress_callback progress_cb,
		//~ void *progress_payload) download_pack;

	//~ /* Checks to see if the transport is connected */
	//~ int function(git_transport *transport) is_connected;

	//~ /* Reads the flags value previously passed into connect() */
	//~ int function(git_transport *transport, int *flags) read_flags;

	//~ /* Cancels any outstanding transport operation */
	//~ void function(git_transport *transport) cancel;

	//~ /* This function is the reverse of connect() -- it terminates the
	 //~ * connection to the remote end. */
	//~ int function(git_transport *transport) close;

	//~ /* Frees/destructs the git_transport object. */
	//~ void function(git_transport *transport) free;
//~ }

//~ enum GIT_TRANSPORT_VERSION = 1;
//~ enum git_transport GIT_TRANSPORT_INIT = { GIT_TRANSPORT_VERSION };

//~ /**
 //~ * Function to use to create a transport from a URL. The transport database
 //~ * is scanned to find a transport that implements the scheme of the URI (i.e.
 //~ * git:// or http://) and a transport object is returned to the caller.
 //~ *
 //~ * @param out The newly created transport (out)
 //~ * @param owner The git_remote which will own this transport
 //~ * @param url The URL to connect to
 //~ * @return 0 or an error code
 //~ */
//~ int git_transport_new(git_transport **out_, git_remote *owner, const(char)* url);

//~ /* Signature of a function which creates a transport */
//~ alias git_transport_cb = int function(git_transport **out_, git_remote *owner, void *param);

//~ /* Transports which come with libgit2 (match git_transport_cb). The expected
 //~ * value for "param" is listed in-line below. */

//~ /**
 //~ * Create an instance of the dummy transport.
 //~ *
 //~ * @param out The newly created transport (out)
 //~ * @param owner The git_remote which will own this transport
 //~ * @param payload You must pass NULL for this parameter.
 //~ * @return 0 or an error code
 //~ */
//~ int git_transport_dummy(
	//~ git_transport **out_,
	//~ git_remote *owner,
	//~ /* NULL */ void *payload);

//~ /**
 //~ * Create an instance of the local transport.
 //~ *
 //~ * @param out The newly created transport (out)
 //~ * @param owner The git_remote which will own this transport
 //~ * @param payload You must pass NULL for this parameter.
 //~ * @return 0 or an error code
 //~ */
//~ int git_transport_local(
	//~ git_transport **out_,
	//~ git_remote *owner,
	//~ /* NULL */ void *payload);

//~ /**
 //~ * Create an instance of the smart transport.
 //~ *
 //~ * @param out The newly created transport (out)
 //~ * @param owner The git_remote which will own this transport
 //~ * @param payload A pointer to a git_smart_subtransport_definition
 //~ * @return 0 or an error code
 //~ */
//~ int git_transport_smart(
	//~ git_transport **out_,
	//~ git_remote *owner,
	//~ /* (git_smart_subtransport_definition *) */ void *payload);

//~ /*
 //~ *** End of base transport interface ***
 //~ *** Begin interface for subtransports for the smart transport ***
 //~ */

//~ /* The smart transport knows how to speak the git protocol, but it has no
 //~ * knowledge of how to establish a connection between it and another endpoint,
 //~ * or how to move data back and forth. For this, a subtransport interface is
 //~ * declared, and the smart transport delegates this work to the subtransports.
 //~ * Three subtransports are implemented: git, http, and winhttp. (The http and
 //~ * winhttp transports each implement both http and https.) */

//~ /* Subtransports can either be RPC = 0 (persistent connection) or RPC = 1
 //~ * (request/response). The smart transport handles the differences in its own
 //~ * logic. The git subtransport is RPC = 0, while http and winhttp are both
 //~ * RPC = 1. */

//~ /* Actions that the smart transport can ask
 //~ * a subtransport to perform */
//~ enum git_smart_service_t {
	//~ GIT_SERVICE_UPLOADPACK_LS = 1,
	//~ GIT_SERVICE_UPLOADPACK = 2,
	//~ GIT_SERVICE_RECEIVEPACK_LS = 3,
	//~ GIT_SERVICE_RECEIVEPACK = 4,
//~ } ;

//~ mixin _ExportEnumMembers!git_smart_service_t;

//~ /* A stream used by the smart transport to read and write data
 //~ * from a subtransport */
//~ struct git_smart_subtransport_stream {
	//~ /* The owning subtransport */
	//~ git_smart_subtransport *subtransport;

	//~ int function(
			//~ git_smart_subtransport_stream *stream,
			//~ char *buffer,
			//~ size_t buf_size,
			//~ size_t *bytes_read) read;

	//~ int function(
			//~ git_smart_subtransport_stream *stream,
			//~ const(char)* buffer,
			//~ size_t len) write;

	//~ void function(
			//~ git_smart_subtransport_stream *stream) free;
//~ } ;

//~ /* An implementation of a subtransport which carries data for the
 //~ * smart transport */
//~ struct git_smart_subtransport {
	//~ int function(
			//~ git_smart_subtransport_stream **out_,
			//~ git_smart_subtransport *transport,
			//~ const(char)* url,
			//~ git_smart_service_t action) action;

	//~ /* Subtransports are guaranteed a call to close() between
	 //~ * calls to action(), except for the following two "natural" progressions
	 //~ * of actions against a constant URL.
	 //~ *
	 //~ * 1. UPLOADPACK_LS -> UPLOADPACK
	 //~ * 2. RECEIVEPACK_LS -> RECEIVEPACK */
	//~ int function(git_smart_subtransport *transport) close;

	//~ void function(git_smart_subtransport *transport) free;
//~ };

//~ /* A function which creates a new subtransport for the smart transport */
//~ alias git_smart_subtransport_cb = int function(
	//~ git_smart_subtransport **out_,
	//~ git_transport* owner);

//~ struct git_smart_subtransport_definition {
	//~ /* The function to use to create the git_smart_subtransport */
	//~ git_smart_subtransport_cb callback;

	//~ /* True if the protocol is stateless; false otherwise. For example,
	 //~ * http:// is stateless, but git:// is not. */
	//~ uint rpc;
//~ } ;

//~ /* Smart transport subtransports that come with libgit2 */

//~ /**
 //~ * Create an instance of the http subtransport. This subtransport
 //~ * also supports https. On Win32, this subtransport may be implemented
 //~ * using the WinHTTP library.
 //~ *
 //~ * @param out The newly created subtransport
 //~ * @param owner The smart transport to own this subtransport
 //~ * @return 0 or an error code
 //~ */
//~ int git_smart_subtransport_http(
	//~ git_smart_subtransport **out_,
	//~ git_transport* owner);

//~ /**
 //~ * Create an instance of the git subtransport.
 //~ *
 //~ * @param out The newly created subtransport
 //~ * @param owner The smart transport to own this subtransport
 //~ * @return 0 or an error code
 //~ */
//~ int git_smart_subtransport_git(
	//~ git_smart_subtransport **out_,
	//~ git_transport* owner);

//~ /**
 //~ * Create an instance of the ssh subtransport.
 //~ *
 //~ * @param out The newly created subtransport
 //~ * @param owner The smart transport to own this subtransport
 //~ * @return 0 or an error code
 //~ */
//~ int git_smart_subtransport_ssh(
	//~ git_smart_subtransport **out_,
	//~ git_transport* owner);
