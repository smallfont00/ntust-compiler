#pragma once

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct token {
    size_t beg;
    size_t len;
} token;

size_t size_token(const void*);

char* get_string(const char*, token);
