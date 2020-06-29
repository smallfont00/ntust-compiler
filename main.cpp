#include <stdio.h>

#include "AST.h"
#include "hashtable.h"
#include "list.h"

extern SymbolTable* current_scope;
extern void lexer_init();
extern int yyparse();

int main(int argc, char** argv) {
    lexer_init();

    yyparse();

    auto obj = dynamic_cast<ObjectAST*>(current_scope);
    obj->find("main");
    std::cout << obj->codegen() << std::endl;
}