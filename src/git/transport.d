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
    // import ssh2;
}

///
enum GitCredType
{
    ///
	userpass_plaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,

    ///
	ssh_keyfile_passphrase = GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE,

    ///
	ssh_publickey = GIT_CREDTYPE_SSH_PUBLICKEY,
}

/* A plaintext username and password. */
struct GitCredPlaintext
{
    enum credType = GitCredType.userpass_plaintext;

	GitCred parent;
	string username;
	string password;
}

/* A ssh key file and passphrase. */
struct GitCredKeyfilePassphrase
{
    enum credType = GitCredType.ssh_keyfile_passphrase;

    GitCred parent;
    string publickey;
    string privatekey;
    string passphrase;
}

/* A ssh public key and authentication callback. */
struct GitCredPublickey
{
    enum credType = GitCredType.ssh_publickey;

    GitCred parent;
    string publickey;
    void* sign_callback;
    void* sign_data;
}

/** Check if type $(D T) is one of the supported git credential types. */
template isGitCredential(T)
{
    enum bool isGitCredential = is(T == GitCredPlaintext) ||
                                is(T == GitCredKeyfilePassphrase) ||
                                is(T == GitCredPublickey);
}

// helper
private template _credToType(GitCredType credType)
{
    static if (credType == GitCredType.userpass_plaintext)
        alias _credToType = GitCredPlaintext;
    else
    static if (credType == GitCredType.ssh_keyfile_passphrase)
        alias _credToType = GitCredKeyfilePassphrase;
    else
    static if (credType == GitCredType.ssh_publickey)
        alias _credToType = GitCredPublickey;
    else
    static assert(0);
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

    T getImpl(T : GitCredPlaintext)()
    {
        auto plaintext = cast(git_cred_userpass_plaintext*)_data._payload;

        T result;
        result.parent = this;
        result.username = to!string(plaintext.username);
        result.password = to!string(plaintext.password);
        return result;
    }

    T getImpl(T : GitCredKeyfilePassphrase)()
    {
        assert(0);
    }

    T getImpl(T : GitCredPublickey)()
    {
        assert(0);
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

/**
    Creates a new plain-text username and password credential object.
    The supplied credential parameter will be internally duplicated.
*/
GitCred createPlainTextCred(string username, string password)
{
    git_cred* _git_cred;
    require(git_cred_userpass_plaintext_new(&_git_cred, username.toStringz, password.toStringz) == 0);
    return GitCred(_git_cred);
}

///
unittest
{
    auto cred = createPlainTextCred("foo", "bar");

    switch (cred.credType) with (GitCredType)
    {
        case userpass_plaintext:
        {
            // throw when trying to cast to an inappropriate type
            assertThrown!GitException(cred.get!ssh_keyfile_passphrase);

            // ditto
            assertThrown!GitException(cred.get!GitCredKeyfilePassphrase);

            auto plain = cred.get!userpass_plaintext;
            assert(plain.username == "foo");
            assert(plain.password == "bar");

            break;
        }

        default: assert(0, text(cred.credType));
    }
}

//~ version (GIT_SSH)
//~ {
    //~ static assert(0, "dlibgit does not support SSH yet.");
    //~ // typedef LIBSSH2_USERAUTH_PUBLICKEY_SIGN_FUNC((*git_cred_sign_callback));

    //~ /**
     //~ * Creates a new ssh key file and passphrase credential object.
     //~ * The supplied credential parameter will be internally duplicated.
     //~ *
     //~ * @param out The newly created credential object.
     //~ * @param publickey The path to the public key of the credential.
     //~ * @param privatekey The path to the private key of the credential.
     //~ * @param passphrase The passphrase of the credential.
     //~ * @return 0 for success or an error code for failure
     //~ */
    //~ int git_cred_ssh_keyfile_passphrase_new(
        //~ git_cred **out_,
        //~ const(char)* publickey,
        //~ const(char)* privatekey,
        //~ const(char)* passphrase);

    //~ /**
     //~ * Creates a new ssh public key credential object.
     //~ * The supplied credential parameter will be internally duplicated.
     //~ *
     //~ * @param out The newly created credential object.
     //~ * @param publickey The bytes of the public key.
     //~ * @param publickey_len The length of the public key in bytes.
     //~ * @param sign_callback The callback method for authenticating.
     //~ * @param sign_data The abstract data sent to the sign_callback method.
     //~ * @return 0 for success or an error code for failure
     //~ */
    //~ int git_cred_ssh_publickey_new(
        //~ git_cred **out_,
        //~ const(char)* publickey,
        //~ size_t publickey_len,
        //~ git_cred_sign_callback,
        //~ void *sign_data);
//~ }

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
