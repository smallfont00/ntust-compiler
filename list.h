#pragma once
#ifndef LIST_H
#define LIST_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    void *value;
    struct Node *next;
} Node;

typedef struct List {
    int id;
    Node *head;
    Node *tail;
    size_t (*size)(const void *);
} List;

#define SIZE(func) ((size_t(*)(const void *))func)

void insert(List *list, const void *value);

List *build_list(size_t (*size)(const void *));

Node *build_node(const void *value, size_t size);

void print_word(Node *word);

void print_line(Node *line);

void traverse(List *list, void (*fun)(Node *));

void tool_test();

size_t size_list(const void *a);

#endif  // !LIST_H
