#pragma once

#include "list.h"

#define SYMBOL_LEN (1 << 16)

// Djb2 hash function (http://www.cse.yorku.ca/~oz/hash.html)
size_t sym_hash(const char *);

// Initialize symbol table.
void sym_create();

// Return a id if it inside the symbol table.
Node *sym_lookup(const char *);

// Insert if id not inside the symbol table.
void sym_insert(const char *);

// Print all id in symbol table.
void sym_dump();

static List *symbol[SYMBOL_LEN];