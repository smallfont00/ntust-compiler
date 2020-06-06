#include "hashtable.h"

#include <string.h>

size_t sym_hash(const char* str) {
    unsigned long hash = 5381;
    int c;
    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }
    return hash % SYMBOL_LEN;
}

void sym_create() {
    for (int i = 0; i < SYMBOL_LEN; i++) {
        symbol[i] = build_list(SIZE(strlen));
    }
}

Node* sym_lookup(const char* str) {
    List* list = symbol[sym_hash(str)];
    Node* node = list->head;
    for (; node; node = node->next) {
        if (strcmp((char*)node->value, str) == 0) break;
    }
    return node;
}

void sym_insert(const char* str) {
    size_t hash = sym_hash(str);
    for (Node* node = symbol[hash]->head; node; node = node->next) {
        if (strcmp((char*)node->value, str) == 0) return;
    }
    insert(symbol[hash], str);
}

void sym_dump() {
    for (size_t i = 0; i < SYMBOL_LEN; i++) {
        for (Node* node = symbol[i]->head; node; node = node->next) {
            printf("%s\n", (char*)node->value);
        }
    }
}