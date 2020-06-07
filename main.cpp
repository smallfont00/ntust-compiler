#include <stdio.h>

#include "hashtable.h"
#include "list.h"
#include "symbol_table.h"

extern void lexer_init();
extern int yyparse();

int main(int argc, char** argv) {
    lexer_init();

    Symbol_table* sym_t = new Symbol_table();

    sym_t->add("a", new type<int>(12));

    yyparse();
}