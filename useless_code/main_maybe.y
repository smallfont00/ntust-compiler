%{
#include <stdio.h>
#include "list.h"
#include "hashtable.h"

int ident = 0;

#define P(S) {/*printf("<" #S ">");*/ printf("%*c" #S "\n", ident * 2, ' '); ident++;}
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


program: tok_object tok_identifier tok_d_lbrack {P(A)} declaration_list {E() P(B)} {E() P(C)} tok_d_rbrack {E() P(D)};

line: '\n' optional_line;

optional_line: /*empty*/
    | '\n' optional_line
    ;

declaration_list: /*empty*/
    | declaration
    | declaration line declaration_list 
    ;

declaration
    : {P(A)} val_dec {E()}
    | {P(B)} var_dec {E()}
    | {P(C)} arr_dec {E()}
    | {P(D)} fun_dec {E()}
    ;

fun_dec: tok_def tok_identifier tok_d_lparen parameters tok_d_rparen type {P(A)} block {E()};

parameters: /*empty*/
    | tok_identifier type parameters_

parameters_: /*empty*/ 
    | tok_d_comma tok_identifier type parameters_ 
    ;

arguments: /*empty*/
    | expr arguments_
    ;

arguments_: /*empty*/
    | tok_d_comma expr arguments_
    ;

statement_list: /*empty*/
    | statement
    | statement line statement_list
    ;

statement
    :{P(A)} declaration                                     {E()}
    |{P(B)} tok_identifier tok_assign expr                  {E()}
    |{P(C)} expr                                            {E()}
    |{P(D)} tok_print tok_d_lparen expr tok_d_rparen        {E()}
    |{P(E)} tok_println tok_d_lparen expr tok_d_rparen      {E()}
    |{P(F)} tok_read tok_identifier                         {E()}
    |{P(G)} tok_return option_expr                          {E()}
    |{P(H)} block                                           {E()}
    |{P(I)} loop                                            {E()}
    |{P(J)} condition                                       {E()}
    ; 

val_dec
    : tok_val tok_identifier type tok_assign expr
    | tok_val tok_identifier type
    ;

var_dec
    : tok_var tok_identifier type tok_assign expr
    | tok_var tok_identifier type
    ;

arr_dec: tok_var tok_identifier type tok_d_lsqure expr tok_d_rsqure;

option_expr: /*empty*/
    | {P(O)} expr {E()}
    ;

type: /*empty*/ | tok_d_colon primitive ;

primitive: tok_int | tok_float | tok_boolean | tok_string;

block: {P(LB) E()} tok_d_lbrack {P(A)} statement_list {E() P(B)} tok_d_rbrack;

expr
    : value
    | tok_not expr
    | expr tok_lt expr
    | expr tok_le expr
    | expr tok_eq expr
    | expr tok_be expr
    | expr tok_bt expr
    | expr tok_ne expr
    | expr tok_and expr
    | expr tok_or expr
    | tok_d_lparen expr tok_d_rparen
    | tok_minus expr %prec UMINUS
    | expr tok_mul expr
    | expr tok_div expr
    | expr tok_mod expr
    | expr tok_add expr
    | expr tok_minus expr
    ;

number: tok_v_int | tok_v_float;

func_call: tok_identifier tok_d_lparen arguments tok_d_rparen;

value
    : tok_true
    | tok_false
    | number
    | func_call
    | tok_identifier
    | tok_v_string
    | tok_d_lparen value tok_d_rparen
    ;

loop
    : tok_while tok_d_lparen expr tok_d_rparen statement
    | tok_for tok_d_lparen tok_identifier tok_d_larrow expr tok_to expr tok_d_rparen statement
    ;

condition
    : tok_if tok_d_lparen expr tok_d_rparen statement %prec LOWER_THAN_ELSE
    | tok_if tok_d_lparen expr tok_d_rparen statement tok_else statement
    ;

tok_boolean: BOOLEAN | BOOLEAN '\n';
tok_break: BREAK | BREAK '\n';
tok_char: CHAR | CHAR '\n';
tok_case: CASE | CASE '\n';
tok_class: CLASS | CLASS '\n';
tok_continue: CONTINUE | CONTINUE '\n';
tok_def: DEF | DEF '\n';
tok_do: DO | DO '\n';
tok_else: ELSE | ELSE '\n';
tok_exit: EXIT | EXIT '\n';
tok_false: FALSE | FALSE '\n';
tok_float: FLOAT | FLOAT '\n';
tok_for: FOR | FOR '\n';
tok_if: IF | IF '\n';
tok_int: INT | INT '\n';
tok_null_: NULL_ | NULL_ '\n';
tok_object: OBJECT | OBJECT '\n';
tok_print: PRINT | PRINT '\n';
tok_println: PRINTLN | PRINTLN '\n';
tok_repeat: REPEAT | REPEAT '\n';
tok_return: RETURN | RETURN '\n';
tok_string: STRING | STRING '\n';
tok_to: TO | TO '\n';
tok_true: TRUE | TRUE '\n';
tok_type: TYPE | TYPE '\n';
tok_val: VAL | VAL '\n';
tok_var: VAR | VAR '\n';
tok_while: WHILE | WHILE '\n';
tok_identifier: IDENTIFIER | IDENTIFIER '\n';
tok_add: ADD | ADD '\n';
tok_minus: MINUS | MINUS '\n';
tok_mul: MUL | MUL '\n';
tok_div: DIV | DIV '\n';
tok_mod: MOD | MOD '\n';
tok_lt: LT | LT '\n';
tok_le: LE | LE '\n';
tok_be: BE | BE '\n';
tok_bt: BT | BT '\n';
tok_eq: EQ | EQ '\n';
tok_ne: NE | NE '\n';
tok_and: AND | AND '\n';
tok_or: OR | OR '\n';
tok_not: NOT | NOT '\n';
tok_d_comma: D_COMMA | D_COMMA '\n';
tok_d_colon: D_COLON | D_COLON '\n';
tok_d_period: D_PERIOD | D_PERIOD '\n';
tok_d_semicolon: D_SEMICOLON | D_SEMICOLON '\n';
tok_d_lparen: D_LPAREN | D_LPAREN '\n';
tok_d_rparen: D_RPAREN | D_RPAREN '\n';
tok_d_lsqure: D_LSQURE | D_LSQURE '\n';
tok_d_rsqure: D_RSQURE | D_RSQURE '\n';
tok_d_lbrack: D_LBRACK | D_LBRACK '\n';
tok_d_rbrack: D_RBRACK | D_RBRACK '\n';
tok_d_larrow: D_LARROW | D_LARROW '\n';
tok_assign: ASSIGN | ASSIGN '\n';
tok_v_int: V_INT | V_INT '\n';
tok_v_bool: V_BOOL | V_BOOL '\n';
tok_v_float: V_FLOAT | V_FLOAT '\n';
tok_v_string: V_STRING | V_STRING '\n';
tok_read: READ | READ '\n';

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
