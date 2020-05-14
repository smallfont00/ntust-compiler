%option noyywrap

%{
#include "list.h"
#include "token.h"
#include <string.h>
#define BUFFER_LEN 8192

char text[BUFFER_LEN];

#define cat_handler(lhs, rhs, offset, stmt) { \
                                            int beg = offset; \
                                            int len = 0; \
                                            sprintf(lhs + offset, "%s%n", rhs, &len); \
                                            offset += len; \
                                            token t = {.beg = beg, .len = len };
                                            stmt; \
                                            }

List *lines;
List *words;
int chars_len = 0;
int lines_len = 0;


%}

delimiters  ","|":"|"."|";"|"("|")"|"["|"]"|"{"|"}"

operator    "+"|"-"|"*"|"/"|"%"|"<"|"<="|">="|">"|"=="|"!="

keyword "boolean"|"break"|"char"|"case"|"class"|"continue"|"def"|"do"|"else"|"exit"|"float"|"for"|"if"|"int"|"null"|"object"|"print"|"println"|"repeat"|"return"|"string"|"to"|"type"|"val"|"var"|"while"

digit   [0-9]
integer {digit}+
bool    "true"|"false"
float   ("+"|"-")?(({digit}*[.]{digit}+)|({digit}+[.]{digit}*))(e("+"|"-")?{integer})?
string  \"([^"\\]|\\.|\"\")*\"

alpha   [a-zA-Z]
identifier  {alpha}+({digit}|{alpha})*

whitespace  [ \t]

line_comment            "//"
left_block_comment      "/*"
right_block_comment     "*/"

%%
{delimiters}    {cat_handler(text, yytex, chars_len, insert(words, t));}
{operator}      {cat_handler(text, yytex, chars_len, insert(words, t));}
{keyword}       {cat_handler(text, yytex, chars_len, insert(words, t));}
{integer}       {cat_handler(text, yytex, chars_len, insert(words, t));}
{bool}          {cat_handler(text, yytex, chars_len, insert(words, t));}
{float}         {cat_handler(text, yytex, chars_len, insert(words, t));}
{string}        {cat_handler(text, yytex, chars_len, insert(words, t));}
{identifier}    {cat_handler(text, yytex, chars_len, insert(words, t));}
{whitespace}    {cat_handler(text, yytex, chars_len, insert(words, t));}

\n                  {
                    chars_len++; 
                    lines_len++; 
                    insert(lines, words); 
                    words = build_list(size_list);
                    }

.                   {
                    chars_len++;
                    }
%%

int main(int argc, char **argv) {
    tool_test();

    lines = build_list(SIZE(strlen));
    words = build_list(size_token);

    yylex();
    traverse(lines, print_line);
    printf("\n");
    printf("%8d%8d%8d\n", lines_len, words_len, chars_len);
}