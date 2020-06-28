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
#include "AST.h"

int ident = 0;

// Print Warning Message
#define W(S) {printf("<" S ">\n"); exit(0); }

SymbolTable *current_scope = nullptr;

SymbolTable * function_block = nullptr;

// Change Current Scope To Deeper Block/Scope
void table_swap_in() {
    if (function_block) {
        function_block->parent = current_scope;
        current_scope = function_block;
        function_block = nullptr;
        return;
    }
    auto * b = new BlockAST(current_scope); 
    current_scope = b;
}

// Change Current Scope To Parent Environment 
void table_swap_out() {
    current_scope = current_scope->parent;
}

%}

%code requires {
    #include <algorithm>
    #include "AST.h"
}

%union {
    AST * __ast;
    NamedAST *__var;
    ExprAST *__expr;
    StatementAST *__stmt;
    std::string* __str;
    std::vector<VariableAST*>* __params;
    std::vector<StatementAST*>* __stmts;
    std::vector<ExprAST*>* __args;
}

%token BREAK CASE CLASS CONTINUE DEF DO ELSE EXIT FOR IF NULL_ OBJECT PRINT PRINTLN REPEAT RETURN TO TYPE VAL VAR WHILE EMPTY_RETURN

%token INT FLOAT BOOLEAN STRING CHAR   

%token <__str> IDENTIFIER

%token ADD MINUS MUL DIV MOD LT LE BE BT EQ NE AND OR NOT
%token EOL LINE
%token D_COMMA D_COLON D_PERIOD D_SEMICOLON D_LPAREN D_RPAREN D_LSQURE D_RSQURE D_LBRACK D_RBRACK D_LARROW
%token ASSIGN

%token <__str> TRUE FALSE V_INT V_FLOAT V_STRING V_CHAR

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

%type <__expr> expr number func_call value
%type <__var> variable
%type <__str> type option_type primitive
%type <__params> parameters parameters_
%type <__args> arguments arguments_
%type <__str> identifer
%type <__stmt> block loop condition statement
%type <__stmts> statement_list
%%

/* Program Start State */
program: ol OBJECT          
         identifer    
         ol D_LBRACK            { current_scope = new ObjectAST(*$3);}
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
declaration_list: /*empty*/                     
    | declaration                               
    | declaration_list line declaration         
    ;

/* 4 difference type of declaration */
declaration
    : val_dec                   
    | var_dec                   
    | arr_dec                   
    | fun_dec                   
    ;

/* Declaration of function */
fun_dec: DEF identifer D_LPAREN parameters D_RPAREN option_type 
        {   /* Notice that the parameters is in inverse order, we must reverse it first. */
            std::reverse($4->begin(), $4->end());
            
            std::string type = "void";
            if ($6->size()) type = *$6;
            auto func = new FunctionAST(*$2, type, *$4);
            current_scope->push(func);

            /* To share the symbol table, I just store it with global variable. The next terminal<block> would use it. */
            function_block = func->block;
        }
        block
        ;

/* Formal parameters */
parameters: /*empty*/ { $$ = new std::vector<VariableAST*>(); }
    | identifer type parameters_ 
        {
            $$ = $3;
            $$->push_back(new VariableAST(*$1, *$2));
        }
    ;

/* Formal parameters */
parameters_: /*empty*/ {$$ =  new std::vector<VariableAST*>();}
    | D_COMMA identifer type parameters_ 
        {
            $$ = $4; 
            $$->push_back(new VariableAST(*$2, *$3)); 
        }
    ;

/* Actual parameters */
arguments: /*empty*/    { $$ = new std::vector<ExprAST*>(); }
    | expr arguments_   {$$ = $2; $$->push_back($1); }
    ;

/* Actual parameters */
arguments_: /*empty*/   { $$ = new std::vector<ExprAST*>(); }
    | D_COMMA expr arguments_ {$$ = $3; $$->push_back($2);  }
    ;

/* Accept a collection of statement (including declaration), Each statement must seperate by lines */
statement_list: /*empty*/                   { $$ = new std::vector<StatementAST*>(); }
    | statement                             { $$ = new std::vector<StatementAST*>(); $$->push_back($1);}
    | statement_list line statement         { $$ = $1; $$->push_back($3); }
    ;

/* Difference types of statement */
statement
    : declaration
        {
            $$ = new NullAST();
        }                      
    | variable ASSIGN expr                  
        {   
            auto var = dynamic_cast<VariableAST*>($1);
            if (!var) Error("[Parser] <%s> is not a variable\n", $1->name);
            $$ = new AssignAST(var, $3);
        }
    | expr
        {
            $$ = $1;
        }
    | PRINT expr 
        {
            auto print = dynamic_cast<FunctionAST*>(current_scope->find("print"));
            if (!print) Error("[Parser] <%s> is not a function\n", "print");
            $$ = new InvokeAST(print, {$2});
        }
    | PRINTLN expr
        {
            auto println = dynamic_cast<FunctionAST*>(current_scope->find("println"));
            if (!println) Error("[Parser] <%s> is not a function\n", "println");
            $$ = new InvokeAST(println, {$2});
        }
    | READ variable
        {
            $$ = new NullAST();
            Error("[Parser] No implement for read\n");
        }
    | EMPTY_RETURN
        {
            $$ = new ReturnAST(new NullAST());
        }
    | RETURN expr
        {
            $$ = new ReturnAST($2);
        }            
    | block
        {
            $$ = $1;
        }                       
    | loop
        {
            $$ = $1;
        }
    | condition
        {
            $$ = $1;
        }         
    ; 

val_dec
    : VAL identifer option_type ASSIGN expr        {
                                            if (($3->size()) && (*$3 != $5->type)) Error("[Parser] Value type not match");
                                            current_scope->push(new VariableAST(*$2, $5, true));
                                            }
    ;

var_dec
    : VAR identifer option_type ASSIGN expr        {
                                            if (($3->size()) && (*$3 != $5->type)) Error("[Parser] Value type not match");
                                            current_scope->push(new VariableAST(*$2, $5));
                                            }
    | VAR identifer option_type                    {
                                            std::string type;
                                            if ($3->size()) type = *$3;
                                            else type = "int";
                                            current_scope->push(new VariableAST(*$2, type));
                                            }
    ;

arr_dec: VAR identifer option_type D_LSQURE expr D_RSQURE
                                            {
                                            Error("[Parser] No implement for array");
                                            }
    ;

type: D_COLON primitive { $$ = $2; };

option_type: /*empty*/ { $$ = new std::string();} | type;

primitive
    : INT       { $$ = new std::string("int");              }
    | FLOAT     { $$ = new std::string("float");            }
    | BOOLEAN   { $$ = new std::string("bool");             }
    | STRING    { $$ = new std::string("java.lang.String"); } 
    | CHAR      { $$ = new std::string("char");             }
    ;

/* Block */
block: ol D_LBRACK                                  { table_swap_in();}
       ol statement_list 
       ol D_RBRACK                                  
       { 
           auto t1 = dynamic_cast<BlockAST*>(current_scope); 
           for (auto stmt : *$5) t1->push(stmt);
           $$ = t1;
           table_swap_out();
       }
    ;

/* Parse Grammar */
/* Type checking is outside the grammar */
/* Association is define at the first section using %left, %right */
expr
    : value                         { $$ = $1; }        
    | NOT expr                      { $$ = new SingleExprAST("!", $2); }            
    | D_LPAREN expr D_RPAREN        { $$ = $2; }                            
    | expr LT expr                  { $$ = new BinaryExprAST("<" , $1, $3); }                
    | expr LE expr                  { $$ = new BinaryExprAST("<=", $1, $3); }                
    | expr EQ expr                  { $$ = new BinaryExprAST("==", $1, $3); }                
    | expr BE expr                  { $$ = new BinaryExprAST(">=", $1, $3); }                
    | expr BT expr                  { $$ = new BinaryExprAST(">" , $1, $3); }                
    | expr NE expr                  { $$ = new BinaryExprAST("!=", $1, $3); }                
    | expr AND expr                 { $$ = new BinaryExprAST("&&", $1, $3); }                
    | expr OR expr                  { $$ = new BinaryExprAST("||", $1, $3); }                
    | expr MUL expr                 { $$ = new BinaryExprAST("*", $1, $3);  }                
    | expr DIV expr                 { $$ = new BinaryExprAST("/", $1, $3);  }                
    | expr ADD expr                 { $$ = new BinaryExprAST("+", $1, $3);  }                
    | expr MINUS expr               { $$ = new BinaryExprAST("-", $1, $3);  }                    
    | expr MOD expr                 { $$ = new BinaryExprAST("%", $1, $3);  }                
    | MINUS expr %prec UMINUS       { $$ = new SingleExprAST("-", $2);      }                            
    ;

number
    : V_INT    {$$ = new ValueAST("int",   *$1);} 
    | V_FLOAT  {$$ = new ValueAST("float", *$1);}
    ;

func_call: variable D_LPAREN arguments D_RPAREN     {
                                                    auto t = dynamic_cast<FunctionAST*>($1);
                                                    if (!t) Error("[Parser] <%s> is not a function\n", $1->name.c_str());
                                                    std::reverse($3->begin(), $3->end());
                                                    $$ = new InvokeAST(t, *$3);
                                                    };

value
    : TRUE                                          {$$ = new ValueAST("bool", "1");}
    | FALSE                                         {$$ = new ValueAST("bool", "0");}
    | number                                        {$$ = $1;}
    | func_call                                     {$$ = $1;}
    | variable                                      {
                                                    auto var = dynamic_cast<VariableAST*>($1);
                                                    if (!var) Error("[Parser] <%s> is not a variable\n", $1->name);
                                                    $$ = var->to_value();
                                                    }
    | V_STRING                                      {$$ = new ValueAST("java.lang.String", *$1);}
    | V_CHAR                                        {$$ = new ValueAST("char", *$1);}
    ;

variable
    : identifer                                     { 
                                                    $$ = current_scope->find(*($1));
                                                    }
    | variable D_LSQURE expr D_RSQURE               {
                                                    Error("[Parser] No implement for array\n");
                                                    }
    ;

loop: WHILE D_LPAREN expr D_RPAREN statement
        {
            $$ = new WhileAST($3, $5);
        }
    | FOR D_LPAREN variable D_LARROW expr TO expr D_RPAREN statement
        {
            $$ = new NullAST();
            Error("[Parser] No implement for for-loop\n");
        }
    ;

condition
    : IF D_LPAREN expr D_RPAREN ol statement %prec LOWER_THAN_ELSE
        {
            $$ = new IfAST($3, $6, new NullAST());
            //fprintf(stderr,"<IF>");
        }
    | IF D_LPAREN expr D_RPAREN ol statement ELSE statement
        {
            $$ = new IfAST($3, $6, $8);
            //fprintf(stderr,"<IF_ELSE>");
        }
    ;


%%

void yyerror(char *s){
    fprintf(stderr, "str: %s\n", yytext);
    fprintf(stderr, "first ascii: %d\n", *yytext);
    fprintf(stderr, "%s\n", s);
}
