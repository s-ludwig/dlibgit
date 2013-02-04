module git2.transport;

import git2.indexer;
import git2.net;
import git2.types;
import std.bitmanip;

extern(C):

enum git_credtype {
	USERPASS_PLAINTEXT = 1,
}

struct git_cred {
	git_credtype credtype;
	void function(git_cred *cred) free;
}

struct git_cred_userpass_plaintext {
	git_cred parent;
	char *username;
	char *password;
}

int git_cred_userpass_plaintext_new(git_cred** out_, const(char)* username, const(char)* password);

alias git_cred_acquire_cb = int function(git_cred **cred, const(char)* url, uint allowed_types, void *payload);

enum git_transport_flags {
	NONE = 0,
	NO_CHECK_CERT = 1
}

alias git_transport_message_cb = void function(const(char)* str, int len, void *data);

struct git_transport {
	uint version_ = GIT_TRANSPORT_VERSION;
	int function(git_transport* transport,
		git_transport_message_cb progress_cb,
		git_transport_message_cb error_cb,
		void* payload) set_callbacks;
	int function(git_transport* transport,
		const(char)* url,
		git_cred_acquire_cb cred_acquire_cb,
		void* cred_acquire_payload,
		int direction,
		int flags) connect;
	int function(git_transport* transport,
		git_headlist_cb list_cb,
		void* payload) ls;
	int function(git_transport* transport, git_push* push) push;
	int function(git_transport* transport,
		git_repository* repo,
		const(git_remote_head*)* refs,
		size_t count) negotiate_fetch;
	int function(git_transport* transport,
		git_repository* repo,
		git_transfer_progress* stats,
		git_transfer_progress_callback progress_cb,
		void *progress_payload) download_pack;
	int function(git_transport* transport) is_connected;
	int function(git_transport* transport, int *flags) read_flags;
	void function(git_transport* transport) cancel;
	int function(git_transport* transport) close;
	void function(git_transport* transport) free;
}

enum GIT_TRANSPORT_VERSION = 1;

int git_transport_new(git_transport** out_, git_remote* owner, const(char)* url);
int git_transport_valid_url(const(char)* url);

alias git_transport_cb = int function(git_transport** out_, git_remote* owner, void* param);

int git_transport_dummy(git_transport** out_, git_remote* owner, void* payload);
int git_transport_local(git_transport** out_, git_remote* owner, void* payload);
int git_transport_smart(git_transport** out_, git_remote* owner, void *payload);

enum git_smart_service {
	UPLOADPACK_LS = 1,
	UPLOADPACK = 2,
	RECEIVEPACK_LS = 3,
	RECEIVEPACK = 4,
}

struct git_smart_subtransport_stream {
	git_smart_subtransport* subtransport;

	int function(git_smart_subtransport_stream* stream, char* buffer, size_t buf_size, size_t* bytes_read) read;
	int function(git_smart_subtransport_stream* stream, const(char)* buffer, size_t len) write;
	void function(git_smart_subtransport_stream* stream) free;
}

struct git_smart_subtransport {
	int function(git_smart_subtransport_stream** out_, git_smart_subtransport* transport, const(char)* url, git_smart_service action) action;
	int function(git_smart_subtransport* transport) close;
	void function(git_smart_subtransport* transport) free;
}

alias git_smart_subtransport_cb = int function(git_smart_subtransport** out_, git_transport* owner);

struct git_smart_subtransport_definition {
	git_smart_subtransport_cb callback;
    mixin(bitfields!(
        uint, "rpc", 1,
        uint, "", 31
    ));
}

int git_smart_subtransport_http(git_smart_subtransport** out_, git_transport* owner);
int git_smart_subtransport_git(git_smart_subtransport** out_, git_transport* owner);
