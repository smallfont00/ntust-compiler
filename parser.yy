%{

extern "C"
{
    int yylex(void);
    void yyerror(char*);
}

extern char *yytext;

#include <stdio.h>
#include "list.h"
#include "hashtable.h"
#include "symbol_table.h"

int ident = 0;

// Print Warning Message
#define W(S) {printf("<" S ">\n"); exit(0); }

Symbol_table *global_scope = new Symbol_table();

Symbol_table *current_scope = nullptr;

Symbol_table * function_block = nullptr;

// Change Current Scope To Deeper Block/Scope
void table_swap_in() {
    if (function_block){
        function_block->parent = current_scope;
        current_scope = function_block;
        function_block = nullptr;
        return;
    }
    Symbol_table * b = new Symbol_table(current_scope); 
    current_scope = b;
}

// Change Current Scope To Parent Environment 
void table_swap_out() {
    current_scope = current_scope->parent;
}

%}

%code requires {
    #include <algorithm>
    #include "symbol_table.h"
}

%union {
    type_ * __type;
    Symbol_table *__sym_t;
    std::string* __str;
    std::vector<std::pair<std::string, type_*>>* __params;
    std::vector<type_*>* __args;

    int __int;
    float __float;
    bool __bool;
    char __char;
}

%token BREAK CASE CLASS CONTINUE DEF DO ELSE EXIT FOR IF NULL_ OBJECT PRINT PRINTLN REPEAT RETURN TO TYPE VAL VAR WHILE

%token <__str>IDENTIFIER
%token <__int> INT FLOAT BOOLEAN STRING CHAR

%token ADD MINUS MUL DIV MOD LT LE BE BT EQ NE AND OR NOT
%token EOL LINE
%token D_COMMA D_COLON D_PERIOD D_SEMICOLON D_LPAREN D_RPAREN D_LSQURE D_RSQURE D_LBRACK D_RBRACK D_LARROW
%token ASSIGN

%token <__bool> TRUE FALSE
%token <__int>V_INT 
%token <__float>V_FLOAT
%token <__str>V_STRING 
%token <__char>V_CHAR

%token READ

/* define the association rule */
%left OR
%left AND
%nonassoc NOT
%left LT LE EQ BE BT NE
%left ADD MINUS
%left MUL DIV MOD
%nonassoc UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%type <__type> expr number func_call value variable;
%type <__int> type primitive;
%type <__params> parameters parameters_
%type <__args> arguments arguments_
%type <__sym_t> block
%type <__str> identifer
%%

/* Program Start State */
program: ol OBJECT          
         identifer    
         ol D_LBRACK            { current_scope = global_scope;}
         ol declaration_list    
         ol D_RBRACK
         ol;        

identifer: ol IDENTIFIER    {$$ = $2;};

/* Accept one or more line */
line: LINE ol;

/* ol mean optional line, I use it anywhere to avoid syntax error */
ol: /*empty*/ 
    | LINE ol
    ;

/* Accept a collection of declaration, Each declaration must seperate by lines */
declaration_list: /*empty*/                     {printf("<C0>");}
    | declaration                               {printf("<C1>");}
    | declaration_list line declaration         {printf("<C2>");}
    ;

/* 4 difference type of declaration */
declaration
    : val_dec                   {printf("<A1>");}
    | var_dec                   {printf("<A2>");}
    | arr_dec                   {printf("<A3>");}
    | fun_dec                   {printf("<A4>");}
    ;

/* Declaration of function */
fun_dec: DEF identifer D_LPAREN parameters D_RPAREN type 
        {   /* Notice that the parameters is in inverse order, we must reverse it first. */

            std::reverse($4->begin(), $4->end()); 
            auto t = DEFINE(func, dynamic_type($6), *$4);
            current_scope->declare(*($2), t);

            /* Parameters are seen as local variable in C, so I decide to share the function's symbol table with block */
            /* To share the symbol table, I just store it with global variable. The next terminal<block> would use it. */
            function_block = t->sym_t;
        }
        block
        { type_cast<func>(current_scope->find_all(*($2)))->define($8); }
        ;

/* Formal parameters */
parameters: /*empty*/ { $$ = new std::vector<std::pair<std::string, type_*>>(); }
    | identifer type parameters_ {
                                  $$ = $3;
                                  $$->push_back({*($1), dynamic_type($2)});
                                  }
    ;

/* Formal parameters */
parameters_: /*empty*/ {$$ =  new std::vector<std::pair<std::string, type_*>>();}
    | D_COMMA identifer type parameters_  { $$ = $4; $$->push_back({*($2), dynamic_type($3)}); }
    ;

/* Actual parameters */
arguments: /*empty*/    { $$ = new std::vector<type_*>(); }
    | expr arguments_   {$$ = $2; $$->push_back($1); }
    ;

/* Actual parameters */
arguments_: /*empty*/   { $$ = new std::vector<type_*>(); }
    | D_COMMA expr arguments_ {$$ = $3; $$->push_back($2);  }
    ;

/* Accept a collection of statement (including declaration), Each statement must seperate by lines */
statement_list: /*empty*/               
    | statement                         
    | statement_list line statement     
    ;

/* Difference types of statement */
statement
    : declaration                           
    | variable ASSIGN expr                  
        {
        /* Assignment with check */
        if($1->is_constant)     W("Variable is Constant"); 
        if (!same_type($1, $3)) W("Assigning Variable Not The Same Type");
        }
    | expr                                  
    | PRINT D_LPAREN expr D_RPAREN          
    | PRINTLN D_LPAREN expr D_RPAREN        
    | READ variable                         
    | RETURN option_expr                    
    | block                                 
    | loop                                  
    | condition                             
    ; 

val_dec
    : VAL identifer type ASSIGN expr       { 
                                            if (($3 != 0) && !same_type(dynamic_type($3), $5)) W("Definition Type Not Compatible");
                                            if (!current_scope->declare(*($2), $5)) W("Re-define Variable Is Not Allow");
                                            }
    ;

var_dec
    : VAR identifer type ASSIGN expr       { 
                                            $5->is_constant = false;
                                            if (($3 != 0) && !same_type(dynamic_type($3), $5)) W("Definition Type Not Compatible");
                                            if (!current_scope->declare(*($2), $5)) W("Re-define Variable Is Not Allow");
                                            }
    | VAR identifer type                   { 
                                            if ($3 == 0) W("Variable Declaration Should Be Typed");
                                            auto t = dynamic_type($3);
                                            t->is_constant = false;
                                            if (!current_scope->declare(*($2), t)) W("Re-define Is Not Allow");
                                            }
    ;

arr_dec: VAR identifer type D_LSQURE expr D_RSQURE
                                            {
                                            if (!type_check<int>($5)) W("Range Must Be Int");
                                            auto t = dynamic_type($3);
                                            if (t == nullptr)  W("Array Declaration Should Be Typed");

                                            auto k = DECLARE(arr);
                                            k->element_type = t;

                                            if (!current_scope->declare(*($2), k)) W("Re-define Variable Is Not Allow");
                                            }
    ;

option_expr: /*empty*/
    | expr
    ;

type: /*empty*/ {$$ = 0;} | D_COLON primitive { $$ = $2;};

primitive: INT | FLOAT | BOOLEAN | STRING | CHAR;

/* Block */
block: ol D_LBRACK              {table_swap_in();}
       ol statement_list 
       ol D_RBRACK                 {$$ = current_scope; table_swap_out();}
    ;

/* Parse Grammar */
/* Type checking is outside the grammar */
/* Association is define at the first section using %left, %right */
expr
    : value                         { $$ = $1;}        
    | NOT expr                      { if(!type_check<bool>($2)) W("Must Be Boolean"); $$ = $2; }            
    | D_LPAREN expr D_RPAREN        { $$ = $2;}                            
    | expr LT expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr LE expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr EQ expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr BE expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr BT expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr NE expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr AND expr                 { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr OR expr                  { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = DECLARE(bool); }                
    | expr MUL expr                 { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = $1; }                
    | expr DIV expr                 { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = $1; }                
    | expr ADD expr                 { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = $1; }                
    | expr MINUS expr               { if(!type_check<int, float>($1, $3)) W("Must Be Number"); $$ = $1; }                    
    | expr MOD expr                 { if(!type_check<int>($1, $3)) W("Must Be Int"); $$ = $1; }                
    | MINUS expr %prec UMINUS       { if(!type_check<int, float>($2)) W("Must Be Number"); $$ = $2; }                            
    ;

number
    : V_INT {$$= DEFINE(int, $1);} 
    | V_FLOAT {$$= DEFINE(float, $1);};

func_call: variable D_LPAREN arguments D_RPAREN { 
                                                    auto t = type_cast<func>($1); 
                                                    if (!t) W("Function Not Exist");
                                                    std::reverse($3->begin(), $3->end());
                                                    if (!t->call_check($3)) W("Parameters Type Not Match");
                                                    $$ = t->ret_val(); 
                                                  };

value
    : TRUE                                          {$$ = TYPE($1);}
    | FALSE                                         {$$ = TYPE($1);}
    | number                                        {$$ = $1;}
    | func_call                                     {$$ = $1;}
    | variable                                      {$$ = $1;}
    | V_STRING                                      {$$ = TYPE(*$1);}
    | V_CHAR                                        {$$ = TYPE($1);}
    ;

variable
    : identifer                                    { 
                                                    $$ = current_scope->find_all(*($1)); 
                                                    if($$ == nullptr) W("Variable Not Found");
                                                    }
    | variable D_LSQURE expr D_RSQURE               {
                                                    if(!type_check<arr>($1)) W("Not An Array");
                                                    if(!type_check<int>($3)) W("Index Must Be Int");
                                                    $$ = type_cast<arr>($1)->element_type;
                                                    }
    ;

loop
    : WHILE D_LPAREN expr D_RPAREN statement
    | FOR D_LPAREN variable D_LARROW expr TO expr D_RPAREN statement
    ;


if_: IF D_LPAREN expr D_RPAREN ol statement;
else_: ELSE statement;

condition
    : if_             %prec LOWER_THAN_ELSE         {printf("<IF>");}
    | if_ else_                                     {printf("<IF_ELSE>");}
    ;


%%

void yyerror(char *s){
    fprintf(stderr, "str: %s\n", yytext);
    fprintf(stderr, "first ascii: %d\n", *yytext);
    fprintf(stderr, "%s\n", s);
}
