#pragma once
#ifndef LIST_H
#define LIST_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Terminology:
//   * generic: can be compatible with all type.
//

// The Node of Linked list with generic value.
typedef struct Node {
    void *value;
    struct Node *next;
} Node;

// Generic Linked list
typedef struct List {
    int id;
    Node *head;
    Node *tail;
    size_t (*size)(const void *);  // Size function for node value, the KEY POINT of making linked list in ANSI C generic.
} List;

// Wrapper: Convert a function pointer with type [size_t func(const char*)] to compatible with the type of size function in linked list.
#define SIZE(func) ((size_t(*)(const void *))func)

// Insert at the end of Linked list.
void insert(List *list, const void *value);

// Insert at the front of Linked list.
void insert_head(List *list, const void *value);

// Initialize a Linked list with size function.
List *build_list(size_t (*size)(const void *));

// Initialize a Node with value. The size is provided by Linked list which own a size function to determine the size of value.
Node *build_node(const void *value, size_t size);

// TEST CODE
void print_word(Node *word);

// TEST CODE
void print_line(Node *line);

// TEST CODE
void traverse(List *list, void (*fun)(Node *));

// TEST CODE
void tool_test();

size_t size_list(const void *a);

#endif  // !LIST_H
