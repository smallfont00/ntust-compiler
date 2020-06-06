%{
#include <stdio.h>
#include "list.h"
#include "hashtable.h"

int ident = 0;

#define P(S) {printf("<" #S ">");/*printf("%*c" #S "\n", ident * 2, ' '); ident++;*/}
#define E() {ident--;}
#define BUFFER_LEN 8192
// Buffer: Keep memorizing a line of code (while matching).
extern char text[BUFFER_LEN];

// Buffer: Cutting of the double quotes of string.
extern char str_buf[BUFFER_LEN];

// Linked list structure of each sigle line of code. (Linked list structure of page)
extern List *context;

// Linked list structure of tokens over a sigle line of code. (Linked list structure of line)
extern List *line;

extern void return_line_token(int flag);

extern int context_len;

%}

%token BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT NULL_ OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE
%token IDENTIFIER
%token ADD MINUS MUL DIV MOD LT LE BE BT EQ NE AND OR NOT
%token EOL LINE
%token D_COMMA D_COLON D_PERIOD D_SEMICOLON D_LPAREN D_RPAREN D_LSQURE D_RSQURE D_LBRACK D_RBRACK D_LARROW
%token ASSIGN
%token V_INT V_BOOL V_FLOAT V_STRING
%token READ

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%left OR
%left AND
%nonassoc NOT
%left LT LE EQ BE BT NE
%left ADD MINUS
%left MUL DIV MOD

%nonassoc UMINUS

%%

program: ol OBJECT ol IDENTIFIER ol D_LBRACK ol {P(A)} declaration_list {E() P(B)} ol {E() P(C)} D_RBRACK {E() P(D)} ol;

ol: optional_line;

line: '\n' optional_line;

optional_line: /*empty*/
    | '\n' optional_line
    ;

declaration_list: /*empty*/
    | declaration line declaration_list 
    ;

declaration
    : {P(A)} val_dec {E()}
    | {P(B)} var_dec {E()}
    | {P(C)} arr_dec {E()}
    | {P(D)} fun_dec {E()}
    ;

fun_dec: DEF IDENTIFIER D_LPAREN parameters D_RPAREN type {P(A)} block {E()};

parameters: /*empty*/
    | IDENTIFIER type parameters_

parameters_: /*empty*/ 
    | D_COMMA IDENTIFIER type parameters_ 
    ;

arguments: /*empty*/
    | expr arguments_
    ;

arguments_: /*empty*/
    | D_COMMA expr arguments_
    ;

statement_list: /*empty*/
    | statement line statement_list
    ;

statement
    :{P(A)} declaration                           {E()}
    |{P(B)} IDENTIFIER ASSIGN expr                {E()}
    |{P(C)} expr                                  {E()}
    |{P(D)} PRINT D_LPAREN expr D_RPAREN          {E()}
    |{P(E)} PRINTLN D_LPAREN expr D_RPAREN        {E()}
    |{P(F)} READ IDENTIFIER                       {E()}
    |{P(G)} RETURN option_expr                    {E()}
    |{P(H)} block                                 {E()}
    |{P(I)} loop                                  {E()}
    |{P(J)} condition                             {E()}
    ; 

val_dec
    : VAL IDENTIFIER type ASSIGN expr
    | VAL IDENTIFIER type
    ;

var_dec
    : VAR IDENTIFIER type ASSIGN expr
    | VAR IDENTIFIER type
    ;

arr_dec: VAR IDENTIFIER type D_LSQURE expr D_RSQURE;

option_expr: /*empty*/
    | {P(O)} expr {E()}
    ;

type: /*empty*/ | D_COLON primitive ;

primitive: INT | FLOAT | BOOLEAN | STRING;

block: {P(LB) E()} ol D_LBRACK ol {P(A)} statement_list {E() P(B)} ol D_RBRACK;

expr
    : value
    | NOT expr
    | expr LT expr
    | expr LE expr
    | expr EQ expr
    | expr BE expr
    | expr BT expr
    | expr NE expr
    | expr AND expr
    | expr OR expr
    | D_LPAREN expr D_RPAREN
    | MINUS expr %prec UMINUS
    | expr MUL expr
    | expr DIV expr
    | expr MOD expr
    | expr ADD expr
    | expr MINUS expr
    ;

number: V_INT | V_FLOAT;

func_call: IDENTIFIER D_LPAREN arguments D_RPAREN;

value
    : TRUE
    | FALSE
    | number
    | func_call
    | IDENTIFIER
    | V_STRING
    | D_LPAREN value D_RPAREN
    ;

loop
    : WHILE D_LPAREN expr D_RPAREN statement
    | FOR D_LPAREN IDENTIFIER D_LARROW expr TO expr D_RPAREN statement
    ;

condition
    : ol IF ol D_LPAREN ol expr ol D_RPAREN ol statement ol %prec LOWER_THAN_ELSE
    | ol IF ol D_LPAREN ol expr ol D_RPAREN ol statement ol ELSE ol statement ol
    ;

%%

int main(int argc, char **argv) {
    return_line_token(0);
    sym_create();

    // Initialize both Linked list structure of page and line.
    context = build_list(size_list);
    line = build_list(SIZE(strlen));
    yyparse();
}

yyerror(char *s){
    fprintf(stderr, "%s\n", s);
}
