%option noyywrap 
%x multiline_comment

%{

extern "C"
{
    int yylex(void);
}

#include "list.h"
#include "hashtable.h"
#include <string.h>
#include <stdlib.h>
#include "parser.h"
#include "symbol_table.h"

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

","     {INSERT; return D_COMMA    ;}
":"     {INSERT; return D_COLON    ;}
"."     {INSERT; return D_PERIOD   ;}
";"     {INSERT; return D_SEMICOLON;}
"("     {INSERT; return D_LPAREN   ;}
")"           {INSERT; return D_RPAREN   ;}
"["     {INSERT; return D_LSQURE   ;}
"]"           {INSERT; return D_RSQURE   ;}
"<-"    {INSERT; return D_LARROW   ;}

"="     {INSERT; return ASSIGN;}

"{"                 {INSERT; return D_LBRACK   ;}
"}"                 {INSERT; return D_RBRACK   ;}


"+"     {INSERT; return ADD;}
"-"     {INSERT; return MINUS;}
"*"     {INSERT; return MUL;}
"/"     {INSERT; return DIV;}
"%"     {INSERT; return MOD;}
"<"     {INSERT; return LT ;}
"<="    {INSERT; return LE ;}
">="    {INSERT; return BE ;}
">"     {INSERT; return BT ;}
"=="    {INSERT; return EQ ;}
"!="    {INSERT; return NE ;}
"&&"    {INSERT; return AND;}
"||"    {INSERT; return OR ;}
"!"     {INSERT; return NOT;}

"int"           { INSERT; yylval.__int = TInt; return INT; }
"float"         { INSERT; yylval.__int = TFloat; return FLOAT; }
"string"        { INSERT; yylval.__int = TString; return STRING; }
"boolean"       { INSERT; yylval.__int = TBoolean; return BOOLEAN; }
"char"          { INSERT; yylval.__int = TChar; return CHAR; }

"case"          { INSERT; return CASE; }
"class"         { INSERT; return CLASS; }
[\n ]*"else"[ \n]+          { INSERT; return ELSE; }
"object"        { INSERT; return OBJECT; }
"to"            { INSERT; return TO; }
"type"          { INSERT; return TYPE; }

"def"                   { INSERT; return DEF; }
"break"                 { INSERT; return BREAK; }
"continue"              { INSERT; return CONTINUE; }
"do"                    { INSERT; return DO; }
"exit"                  { INSERT; return EXIT; }
"for"                   { INSERT; return FOR; }
"if"                    { INSERT; return IF; }
"null"                  { INSERT; return NULL_; }
"print"                 { INSERT; return PRINT; }
"println"               { INSERT; return PRINTLN; }
"repeat"                { INSERT; return REPEAT; }
"return"                { INSERT; return RETURN; }
"val"                   { INSERT; return VAL; }
"var"                   { INSERT; return VAR; }
"while"                 { INSERT; return WHILE; }

"read"                  { INSERT; return READ; }

"true"                  { INSERT; yylval.__bool = true; return TRUE; }
"false"                 { INSERT; yylval.__bool = false; return FALSE; }
{integer}               { INSERT; yylval.__int = atoi(yytext); return V_INT; }
"'"({alpha}|{digit})"'"   { INSERT; yylval.__char = yytext[1]; return V_CHAR;}
{float}                 { INSERT; yylval.__float = atof(yytext); return V_FLOAT;}
{string}                { INSERT_STR; yylval.__str = new std::string(yytext); return V_STRING;}
{identifier}            { INSERT; yylval.__str = new std::string(yytext); return IDENTIFIER;}

{line_comment}  { LINE_SKIP;}

{LB_comment}    { printf("%s", yytext); strcat(text, yytext);BEGIN multiline_comment;}

<multiline_comment>\n              {LINE_SKIP;}
<multiline_comment>.               {printf("%s", yytext); strcat(text, yytext);}
<multiline_comment>{RB_comment}    {printf("%s", yytext); strcat(text, yytext); BEGIN INITIAL;}

{whitespace} {strcat(text, yytext); printf("%s", yytext);}
. {strcat(text, yytext); printf("%s", yytext); return *yytext;}
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

void lexer_init() {
    sym_create();

    // Initialize both Linked list structure of page and line.
    context = build_list(size_list);
    line = build_list(SIZE(strlen));
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