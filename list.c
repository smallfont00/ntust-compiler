#include "list.h"

void insert(List *list, const void *value) {
    Node *node = build_node(value, list->size(value));

    if (!list->head) {
        list->head = list->tail = node;
        return;
    }

    list->tail->next = node;
    list->tail = list->tail->next;
}

void insert_head(List *list, const void *value) {
    Node *node = build_node(value, list->size(value));

    if (!list->head) {
        list->head = list->tail = node;
        return;
    }

    node->next = list->head;
    list->head = node;
}

List *build_list(size_t (*size)(const void *)) {
    List *list = (List *)calloc(1, sizeof(List));
    list->size = size;
    return list;
}

Node *build_node(const void *value, size_t size) {
    Node *node = (Node *)calloc(1, size);
    node->value = malloc(size);
    memcpy(node->value, value, size);
    return node;
}

void traverse(List *list, void (*func)(Node *)) {
    for (Node *node = list->head; node; node = node->next) func(node);
}

void print_word(Node *word) {
    printf("%s ", (char *)word->value);
}

void print_line(Node *line) {
    traverse((List *)line->value, print_word);
    printf("\n");
}

size_t size_list(const void *a) {
    return sizeof(List);
}

void tool_test() {
    List *w1 = build_list(SIZE(strlen));
    List *w2 = build_list(SIZE(strlen));

    List *lines = build_list(size_list);

    traverse(w1, print_word);

    insert(w1, "fuck");
    insert(w1, "you");
    insert_head(w1, "gonna");
    insert_head(w1, "I'm");

    insert(w2, "my");
    insert(w2, "son");

    insert(lines, w1);
    insert(lines, w2);

    traverse(lines, print_line);
    printf("\n");
}