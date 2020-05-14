#include "token.h"

size_t size_token(const void* a) { return sizeof(token); }

char* get_string(const char* str, token t) {
    char* substr = malloc(t.len + 1);
    strncpy(substr, str + t.beg, t.len);
    substr[t.len + 1] = '\0';
    return substr;
}