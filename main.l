%option noyywrap 
%x multiline_comment

%{
#include "list.h"
#include "hashtable.h"
#include <string.h>
#include <stdlib.h>
#include "main.tab.h"

#define BUFFER_LEN 8192

// Simplify version of token identifier code
// enum yytokentype {
//     DELIMITER=258,
//     OPERATOR,
//     KEYWORD,
//     INT,
//     BOOL,
//     FLOAT,
//     STRING,
//     IDENTIFIER,
// };

// Buffer: Keep memorizing a line of code (while matching).
char text[BUFFER_LEN] = { 0 };

// Buffer: Cutting of the double quotes of string.
char str_buf[BUFFER_LEN] = { 0 };

// Linked list structure of each sigle line of code. (Linked list structure of page)
List *context;

// Linked list structure of tokens over a sigle line of code. (Linked list structure of line)
List *line;

int return_flag = 0;

// Handler: Use it at different type of lexical unit.
//   * INSERT:          Maintain the text buffer and Linked list structure of page.
//   * INSERT_STR:      Same as INSERT but cut off the two double quotes of string when inserting to <line>;
//   * LINE:            Maintain and Echo the line message. 
#define INSERT      { strcat(text, yytext); printf("%s", yytext); insert(line, yytext); }
#define INSERT_STR  { strcat(text, yytext); printf("%s", yytext); size_t len = strlen(yytext); memcpy(str_buf, yytext + 1, len - 2); str_buf[len] = '\0'; insert(line, str_buf);}
#define LINE_SKIP   { strcat(text, yytext); printf("%s", yytext); context_len++; /*printf("%d: %s", context_len, text);*/ text[0] = '\0';}

// The number of line.
int context_len = 0;


%}

delimiter   ","|":"|"."|";"|"("|")"|"["|"]"|"{"|"}"

operator    "+"|"-"|"*"|"/"|"%"|"<"|"<="|">="|">"|"=="|"!="|"&&"|"||"|"!"

keyword "boolean"|"break"|"char"|"case"|"class"|"continue"|"def"|"do"|"else"|"exit"|"float"|"for"|"if"|"int"|"null"|"object"|"print"|"println"|"repeat"|"return"|"string"|"to"|"type"|"val"|"var"|"while"

digit   [0-9]
integer {digit}+

float   ("+"|"-")?(({digit}*[.]{digit}+)|({digit}+[.]{digit}*))(e("+"|"-")?{integer})?
string  \"([^"\\]|\\.|\"\")*\"

alpha   [A-Za-z]
identifier  {alpha}({digit}|{alpha})*

whitespace  [ \t]

line_comment    "//".*\n
LB_comment      "/*"
RB_comment     "*/"

%%

[\n ]*","[\n ]*     {INSERT; return D_COMMA    ;}
[\n ]*":"[\n ]*     {INSERT; return D_COLON    ;}
[\n ]*"."[\n ]*     {INSERT; return D_PERIOD   ;}
[\n ]*";"[\n ]*     {INSERT; return D_SEMICOLON;}
[\n ]*"("[\n ]*     {INSERT; return D_LPAREN   ;}
[\n ]*")"           {INSERT; return D_RPAREN   ;}
[\n ]*"["[\n ]*     {INSERT; return D_LSQURE   ;}
[\n ]*"]"           {INSERT; return D_RSQURE   ;}
[\n ]*"<-"[\n ]*    {INSERT; return D_LARROW   ;}

[\n ]*"="[\n ]*     {INSERT; return ASSIGN;}

"{"                 {INSERT; return D_LBRACK   ;}
"}"                 {INSERT; return D_RBRACK   ;}


"+"[\n ]*     {INSERT; return ADD;}
"-"[\n ]*     {INSERT; return MINUS;}
"*"[\n ]*     {INSERT; return MUL;}
"/"[\n ]*     {INSERT; return DIV;}
"%"[\n ]*     {INSERT; return MOD;}
"<"[\n ]*     {INSERT; return LT ;}
"<="[\n ]*    {INSERT; return LE ;}
">="[\n ]*    {INSERT; return BE ;}
">"[\n ]*     {INSERT; return BT ;}
"=="[\n ]*    {INSERT; return EQ ;}
"!="[\n ]*    {INSERT; return NE ;}
"&&"[\n ]*    {INSERT; return AND;}
"||"[\n ]*    {INSERT; return OR ;}
"!"[\n ]*     {INSERT; return NOT;}

[\n ]*"boolean"       { INSERT; return BOOLEAN; }
[\n ]*"char"          { INSERT; return CHAR; }
[\n ]*"case"          { INSERT; return CASE; }
[\n ]*"class"         { INSERT; return CLASS; }
[\n ]*"else"          { INSERT; return ELSE; }
[\n ]*"float"         { INSERT; return FLOAT; }
[\n ]*"int"           { INSERT; return INT; }
[\n ]*"object"        { INSERT; return OBJECT; }
[\n ]*"string"        { INSERT; return STRING; }
[\n ]*"to"            { INSERT; return TO; }
[\n ]*"type"          { INSERT; return TYPE; }

"def"           { INSERT; return DEF; }
"break"         { INSERT; return BREAK; }
"continue"      { INSERT; return CONTINUE; }
"do"            { INSERT; return DO; }
"exit"          { INSERT; return EXIT; }
"false"         { INSERT; return FALSE; }
"for"           { INSERT; return FOR; }
"if"            { INSERT; return IF; }
"null"          { INSERT; return NULL_; }
"print"         { INSERT; return PRINT; }
"println"       { INSERT; return PRINTLN; }
"repeat"        { INSERT; return REPEAT; }
"return"        { INSERT; return RETURN; }
"true"          { INSERT; return TRUE; }
"val"           { INSERT; return VAL; }
"var"           { INSERT; return VAR; }
"while"         { INSERT; return WHILE; }

"read"          { INSERT; return READ; }

{integer}       {INSERT; return V_INT; }

{float}         {INSERT; return V_FLOAT;}
{string}        {INSERT_STR; return V_STRING;}
{identifier}    {INSERT; return IDENTIFIER;}

{line_comment}  {LINE_SKIP;}

{LB_comment}    { printf("%s", yytext); strcat(text, yytext);BEGIN multiline_comment;}

<multiline_comment>\n              {LINE_SKIP;}
<multiline_comment>.               {printf("%s", yytext); strcat(text, yytext);}
<multiline_comment>{RB_comment}    {printf("%s", yytext); strcat(text, yytext); BEGIN INITIAL;}

. {strcat(text, yytext); printf(" ", yytext);}
\n {LINE_SKIP; return LINE;}

<<EOF>>             {
                    LINE_SKIP;
                    return 0;
                    }
%%

// Make all letter in <str> uppercase. 
void string_toupper(char* str) {
    for (; *str; str++) {
        if (((*str) >= 'a') && ((*str) <= 'z')) {
            *str = *str - 'a' + 'A';
        }
    }
}

void return_line_token(int flag) {
    return_flag = flag;
}

/*
int main(int argc, char **argv) {
    sym_create();

    // Initialize both Linked list structure of page and line.
    context = build_list(size_list);
    line = build_list(SIZE(strlen));
    
    int token = 0 ;
    int eof_flag = 0;

    // Keep tracking until matching a EOF.
    while((!eof_flag) && (token = yylex())) {
        char* str = (line->tail) ? (char*) (line->tail->value) : NULL;

        switch(token) {
            case DELIMITER:     printf("<'%s'>\n", str); 
                                break;
            case OPERATOR:      printf("<'%s'>\n", str); 
                                break;
            case KEYWORD:       string_toupper(str); 
                                printf("<%s>\n", str); 
                                break;
            case INT:           printf("<integer:%s>\n", str); 
                                break;
            case BOOL:          printf("<boolean:%s>\n", str); 
                                break;
            case FLOAT:         printf("<float:%s>\n", str); 
                                break;
            case STRING:        printf("<string:%s>\n", str); 
                                break;
            case IDENTIFIER:    sym_insert(str);  
                                printf("<id: %s>\n", str); 
                                break;
            default:            eof_flag = 1;
                                break;
        }
    }
    printf("\n\n");

    // Print all the symbol/identifier
    sym_dump();
}
*/