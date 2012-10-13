module git2.message;

extern(C):

int git_message_prettify(char* message_out, size_t buffer_size, const(char)* message, int strip_comments);
