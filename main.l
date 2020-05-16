%option noyywrap
%x multiline_comment

%{
#include "list.h"
#include "hashtable.h"
#include <string.h>
#include <stdlib.h>

#define BUFFER_LEN 8192

// Simplify version of token identifier code
enum yytokentype {
    DELIMITER=258,
    OPERATOR,
    KEYWORD,
    INTEGER,
    BOOL,
    FLOAT,
    STRING,
    IDENTIFIER,
};

// Buffer: Keep memorizing a line of code (while matching).
static char text[BUFFER_LEN] = { 0 };

// Buffer: Cutting of the double quotes of string.
static char str_buf[BUFFER_LEN] = { 0 };

// Linked list structure of each sigle line of code. (Linked list structure of page)
static List *context;

// Linked list structure of tokens over a sigle line of code. (Linked list structure of line)
static List *line;

// Handler: Use it at different type of lexical unit.
//   * INSERT:          Maintain the text buffer and Linked list structure of page.
//   * INSERT_STR:      Same as INSERT but cut off the two double quotes of string when inserting to <line>;
//   * LINE:            Maintain and Echo the line message. 
#define INSERT      { strcat(text, yytext); insert(line, yytext); }
#define INSERT_STR  { strcat(text, yytext); size_t len = strlen(yytext); memcpy(str_buf, yytext + 1, len - 2); str_buf[len] = '\0'; insert(line, str_buf);}
#define LINE        { strcat(text, yytext); context_len++; printf("%d: %s", context_len, text); text[0] = '\0';}

// The number of line.
static int context_len = 0;


%}

delimiter   ","|":"|"."|";"|"("|")"|"["|"]"|"{"|"}"

operator    "+"|"-"|"*"|"/"|"%"|"<"|"<="|">="|">"|"=="|"!="|"&&"|"||"|"!"

keyword "boolean"|"break"|"char"|"case"|"class"|"continue"|"def"|"do"|"else"|"exit"|"float"|"for"|"if"|"int"|"null"|"object"|"print"|"println"|"repeat"|"return"|"string"|"to"|"type"|"val"|"var"|"while"

digit   [0-9]
integer {digit}+
bool    "true"|"false"
float   ("+"|"-")?(({digit}*[.]{digit}+)|({digit}+[.]{digit}*))(e("+"|"-")?{integer})?
string  \"([^"\\]|\\.|\"\")*\"

alpha   [A-Za-z]
identifier  {alpha}({digit}|{alpha})*

whitespace  [ \t]

line_comment    "//".*\n
LB_comment      "/*"
RB_comment     "*/"

%%

{delimiter}     {INSERT; return DELIMITER;}
{operator}      {INSERT; return OPERATOR;}
{keyword}       {INSERT; return KEYWORD;}
{integer}       {INSERT; return INTEGER; }
{bool}          {INSERT; return BOOL;}
{float}         {INSERT; return FLOAT;}
{string}        {INSERT_STR; return STRING;}
{identifier}    {INSERT; return IDENTIFIER;}

{whitespace}    {strcat(text, yytext);}
{line_comment}  {LINE;}

{LB_comment}    {strcat(text, yytext);  BEGIN multiline_comment;}

<multiline_comment>\n              {LINE;}
<multiline_comment>.               {strcat(text, yytext);}
<multiline_comment>{RB_comment}    {strcat(text, yytext); BEGIN INITIAL;}

\n                  {
                    LINE;
                    line->id = context_len;
                    insert(context, line); 
                    line = build_list(SIZE(strlen));
                    }

.                   {
                    INSERT;
                    return OPERATOR;
                    }

<<EOF>>             {
                    LINE;
                    return -1;
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
            case INTEGER:       printf("<integer:%s>\n", str); 
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