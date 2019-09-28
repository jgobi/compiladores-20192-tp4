%{
    int num_linha = 1;
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
char_const      '([^\n'\\]|\\(1?[0-7]?[0-7]|x[0-9A-Fa-f]?[0-9A-Fa-f]|['abefnrtv\\?]))'

type            integer|real|boolean|char
boolean_const   true|false

RELOP           =|<|<=|>|>=|!=|NOT
ADDOP           \+|-|or
MULOP           \*|\/|div|mod|and

WS              [\t ]+

%%

program         {printf("<program>\n");}
begin           {printf("<begin>\n");}
end             {printf("<end>\n");}
if              {printf("<if>\n");}
then            {printf("<then>\n");}
else            {printf("<else>\n");}
do              {printf("<do>\n");}
while           {printf("<while>\n");}
until           {printf("<until>\n");}
read            {printf("<read>\n");}
write           {printf("<write>\n");}


[:;,()]         {printf("<%s>\n", yytext);}
:=              {printf("<assign>\n");}

{type}          {printf("<type, %s>\n", yytext);}
{boolean_const} {printf("<boolean_const, %s>\n", yytext);}
{integer_const} {printf("<integer_const, %s>\n", yytext);}
{real_const}    {printf("<real_const, %s>\n", yytext);}
{char_const}    {printf("<char_const, %s>\n", yytext);}

{RELOP}         {printf("<RELOP, %s>\n", yytext);}
{ADDOP}         {printf("<ADDOP, %s>\n", yytext);}
{MULOP}         {printf("<MULOP, %s>\n", yytext);}

{identifier}    {printf("<identifier,%s>\n", yytext);}

{WS}            {/*do nothing*/}
\n              {num_linha++;}
.               {fprintf(stderr, "Caractere inesperado na linha %i: %s\n", num_linha, yytext);exit(1);}

%%
int yywrap(){
    return 1;
}
