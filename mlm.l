%{
    #include "string.h"
    #include "mlm.tab.h"
    int num_linha = 1;
    char true_str[] = "true";
%}

letter          [A-Za-z]
digit           [0-9]

identifier      {letter}({letter}|{digit})*
unsigned_int    {digit}+
sign            [+-]
scale_factor    E{sign}?{unsigned_int}
unsigned_real   {unsigned_int}(\.{digit}*)?{scale_factor}?
integer_const   {unsigned_int}
real_const      {unsigned_real}
char_const      '([^\n'\\]|\\['nt0\\])'

type            integer|real|boolean|char
boolean_const   true|false

RELOP           =|<|<=|>|>=|!=
ADDOP           \+|or
MULOP           \*|\/|div|mod|and

WS              [\t ]+

%%

program         {return PROGRAM;}
begin           {return BEGIN_T;}
end             {return END;}
if              {return IF;}
then            {return THEN;}
else            {return ELSE;}
do              {return DO;}
while           {return WHILE;}
until           {return UNTIL;}
read            {return READ;}
write           {return WRITE;}


[:]             {return TWO_DOTS;}
[;]             {return DOT_COMMA;}
[,]             {return COMMA;}
[(]             {return OPEN_PAR;}
[)]             {return CLOSE_PAR;}
:=              {return ASSIGN;}

{type}          {yylval.string = strdup(yytext); return TYPE;}
{boolean_const} {yylval.intval = (strcmp(yytext, true_str) == 0 ? 1 : 0); return BOOLEAN_CONST;}
{integer_const} {yylval.intval = atoi(yytext); return INTEGER_CONST;}
{real_const}    {yylval.val = atof(yytext); return REAL_CONST;}
{char_const}    {yylval.string = strdup(yytext); return CHAR_CONST;}

NOT             {return NOT;}
{RELOP}         {yylval.string = strdup(yytext); return RELOP;}
-               {return MINUS;}
{ADDOP}         {yylval.string = strdup(yytext); return ADDOP;}
{MULOP}         {yylval.string = strdup(yytext); return MULOP;}

{identifier}    {yylval.string = strdup(yytext); return IDENTIFIER;}

{WS}            {/*do nothing*/}
\n              {num_linha++;}
.               {fprintf(stderr, "Caractere inesperado na linha %i: %s\n", num_linha, yytext);exit(1);}

%%
int yywrap(){
    return 1;
}
