module git2.message;

import mingw.lib.gcc.mingw32._4._6._1.include.stddef;

extern(C):

int git_message_prettify(char* message_out, size_t buffer_size, const(char)* message, int strip_comments);
