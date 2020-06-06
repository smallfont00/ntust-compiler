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

extern char *yytext;

%}


%token BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT NULL_ OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE
%token IDENTIFIER
%token ADD MINUS MUL DIV MOD LT LE BE BT EQ NE AND OR NOT
%token EOL LINE
%token D_COMMA D_COLON D_PERIOD D_SEMICOLON D_LPAREN D_RPAREN D_LSQURE D_RSQURE D_LBRACK D_RBRACK D_LARROW
%token ASSIGN
%token V_INT V_BOOL V_FLOAT V_STRING
%token READ

%left OR
%left AND
%nonassoc NOT
%left LT LE EQ BE BT NE
%left ADD MINUS
%left MUL DIV MOD
%nonassoc UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE



%%

program: OBJECT ol IDENTIFIER ol D_LBRACK declaration_list D_RBRACK ol;

line: LINE ol;

ol: /*empty*/ 
    | LINE ol
    ;

declaration_list: /*empty*/ 
    | declaration
    | declaration_list line declaration_list 
    ;

declaration
    : val_dec
    | var_dec
    | arr_dec
    | fun_dec
    ;

fun_dec: DEF IDENTIFIER D_LPAREN parameters D_RPAREN type block;

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

statement_list: /*empty*/ {P(EMPTY)}
    | statement {P(A)}
    | statement_list line statement {P(B)}
    ;
    
statement
    : declaration                           {P(1)}
    | IDENTIFIER ASSIGN expr                {P(2)}
    | expr                                  {P(3)}
    | PRINT D_LPAREN expr D_RPAREN          {P(4)}
    | PRINTLN D_LPAREN expr D_RPAREN        {P(5)}
    | READ IDENTIFIER                       {P(6)}
    | RETURN option_expr                    {P(7)}
    | block                                 {P(8)}
    | loop                                  {P(9)}
    | condition                             {P(0)}
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
    | expr
    ;

type: /*empty*/ | D_COLON primitive ;

primitive: INT | FLOAT | BOOLEAN | STRING;

block: ol D_LBRACK ol statement_list ol D_RBRACK;

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

func_call: IDENTIFIER D_LPAREN arguments D_RPAREN {P(func)};

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


if_: IF D_LPAREN expr D_RPAREN ol statement;
else_: ELSE ol statement;

condition
    : if_             %prec LOWER_THAN_ELSE      {P(IF_THEN)}
    | if_ else_                                  {P(IF_ELSE)}   
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

void yyerror(char *s){
    fprintf(stderr, "str: %s\n", yytext);
    fprintf(stderr, "%s\n", s);
}
