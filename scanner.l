%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
int debugL = 1;

void removeSpaces(char *str) {
    char *new = (char*)malloc(sizeof(char)*strlen(str));
    for (int i = 0, j = 0; i < strlen(str); i++) {
        if (str[i] != ' ') {
            new[j] = str[i];
            j++;
        }
    }
    //if(debugL) printf("in removeSpaces, Before removing spaces: %s\n", str);
    strcpy(str, new);
    // add code to print str before and after removing spaces
    //if(debugL) printf("in removeSpaces, After removing spaces: %s\n", new);

}
%}
%x COMMENT
%x MULTIPLE_COMMENTS

ID (_|[a-zA-Z])(_|[a-zA-Z]|[0-9])*
TYPE (("const"(" ")+)?("signed"(" ")+|"unsigned"(" ")+)?("long long"(" ")+|"long"(" ")+|"short"(" ")+)?"int")|(("const"(" ")+)?("signed"(" ")+|"unsigned"(" ")+)?("long long"|"long"|"short"|"char"))|(("const"(" ")+)?("signed"|"unsigned"|"float"|"double"|"void"))|"const"|"char"|"signed"|"unsigned"|"float"|"double"|"void"
NUMBER [0-9]+
STRING \"(\\.|[^\n"\\])*\" 
CHAR \'(\\.|[^\n'\\])\' 
FLOAT [+-]?("."[0-9]+|[0-9]+"."|[0-9]+"."[0-9]+)
LINE "\n"

%%
"HIGH" {
    yylval.intval = 1;
    return SIGNAL_LV;
}

"LOW" {
    yylval.intval = 0;
    return SIGNAL_LV;
}
"/*" {
    BEGIN MULTIPLE_COMMENTS;
}

"//" {
    BEGIN COMMENT;
}

<MULTIPLE_COMMENTS>([^\n]) {
    
}

<MULTIPLE_COMMENTS>"*/" {
    BEGIN 0;
}

<COMMENT>[^\n] {
    
}

<MULTIPLE_COMMENTS>{LINE} {
    
}

<COMMENT>{LINE} {
    BEGIN 0;
}

";" { return SEMICOLON; }
"," {return COMMA; }
"*" { return STAR; }
"[" { return LSQBRACK;}
"]" { return RSQBRACK;}
"(" { return LPAREN;}
")" { return RPAREN;}


"+" { return PLUS; }
"-" { return MINUS; }
"/" { return DIVIDE; }
"%" { return MOD; }
"==" { return EQ; }
"!=" { return NOTEQ; }
"<" { return LT; }
">" { return GT; }
"<=" { return LTE; }
">=" { return GTE; }
"&&" { return ANDAND; }
"||" { return OROR; }
"!" { return NOT; }
"&" { return AND; }
"^" { return BITWISE_XOR; }
"|" { return BITWISE_OR; }
"<<" { return LEFT_SHIFT; }
">>" { return RIGHT_SHIFT; }
"~" { return BITWISE_NOT; }
"++" { return INC; }
"--" { return DEC; }
"=" { return ASSIGN; }

"if" { return IF; }
"else" { return ELSE; }
"while" { return WHILE; }
"for" { return FOR; }
"return" { return RETURN; }
"break" { return BREAK; }
"continue" { return CONTINUE; }
"{" { return LCURLYBRACE; }
"}" { return RCURLYBRACE; }
"case" { return CASE; }
"default" { return DEFAULT; }
"switch" { return SWITCH; }
":" { return COLON; }
"do" { return DO; }

{TYPE} { 
    removeSpaces(yytext);
    yylval.stringVal = strdup(yytext); return TYPE;
    }

{ID} { 
    yylval.stringVal = strdup(yytext); return ID; 
    }
{NUMBER} {
    yylval.intVal = atoi(yytext);
    return NUMBER;
    
}

{FLOAT} {
    yylval.doubleVal = atof(yytext);
    return DOUBLE;
}


{STRING} {
    yylval.stringVal = strdup(yytext);
    return STRING;
}

{CHAR} {
    yylval.stringVal = yytext;
    return CHAR;
}


[ \t\n] ; /* Ignore whitespace */

. { return yytext[0]; } /* Any other character is an error */

%%

int yywrap() { return 1; }