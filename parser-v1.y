%{
#include <stdio.h>
#include <stdlib.h>
#include "code.h"
int yylex();

int dbg=0;
int lineNo = 1;
int in_if = 0;
int in_while = 0;
int in_for = 0;
int is_array = 0;
int arg_cnt;
int assignflag = 0;
int do_flag=0;

int lineNum = 1;

int DEBUG = 0;          //to be set to 0 later
extern FILE* f_asm;

char* my_itoa(int i) {      //int to string
    int t = 1;
    int tmp = i;
    while (tmp > 9) {
        t++;
        tmp = tmp/10;
    }
    char *new_str = (char*) malloc(sizeof(char)*(t+1));
    sprintf(new_str, "%d", i);
    return new_str;
}

char* my_dtoa(double f) {       //double to string
    char *new_str = (char*)malloc(sizeof(char)*33);
    sprintf(new_str, "%f", f);
    return new_str;
}


%}
%union {
    int intVal;
    double doubleVal;
    char* stringVal;
}

%token <stringVal> ID TYPE CHAR STRING
%token <intVal> NUMBER
%token <doubleVal> DOUBLE

%token <stringVal> SEMICOLON COMMA COLON
%token <stringVal> LPAREN RPAREN LSQBRACK RSQBRACK LCURLYBRACE RCURLYBRACE

%token <stringVal> PLUS MINUS STAR DIVIDE MOD
%token <stringVal> EQ NOTEQ LT GT LTE GTE ASSIGN
%token <stringVal> ANDAND OROR NOT
%token <stringVal> BITWISE_NOT AND BITWISE_XOR BITWISE_OR
%token <stringVal> LEFT_SHIFT RIGHT_SHIFT DEREF INC DEC

%token <stringVal> BREAK CONTINUE SWITCH IF ELSE WHILE FOR DO RETURN
%token <stringVal> CASE DEFAULT

// NEW TOKEN FOR HW3


%type <stringVal> declaration type id  non_ptr_array_id declr_or_def
%type <stringVal> scalar_decl idents option id_assignment ptr_assignee

%type <stringVal> assign_expr expr term 
%type <stringVal> bitwise_or_expr bitwise_xor_expr bitwise_and_expr
%type <stringVal> factor primary atom unary_expr post_expr paren_expr var
%type <intVal> literal array_dim

%type <stringVal> stmts stmt if_else_stmt switch_stmt while_stmt for_stmt return_stmt compound_stmt comp_stmt_content
%type <stringVal> switch_clauses switch_clause for_condition for_last_condition

%type <stringVal> array_decl arrays array_id
%type <stringVal> funtion_decl function_def params param arg_list




%right ASSIGN
%left OROR
%left ANDAND
%left BITWISE_OR
%left BITWISE_XOR
%nonassoc EQ NOTEQ
%nonassoc LT LTE GT GTE
%left LEFT_SHIFT RIGHT_SHIFT
%left PLUS MINUS
%left STAR DIVIDE MOD
%right NOT BITWISE_NOT
%nonassoc UPLUS UMINUS DEREF ADDR_OF
%nonassoc POSTFIX_INC POSTFIX_DEC 

%%

start
    : declr_or_def {  }
    ;

declr_or_def
    : declr_or_def option  { 

    }
    | option  {}
    ;

option
    :declaration
    | function_def {  }
    ;

declaration
    : scalar_decl{ $$=$1; }
    | array_decl  { $$=$1;}
    | funtion_decl {  $$=$1; }
    ;

/*******SCALAR DECLARATION********/

scalar_decl
    : type idents SEMICOLON { 

    }
    ;
idents
    : idents COMMA id_assignment {
        // $$=$1; have/don't have shld make no difference

    }
    | id_assignment {

    }
    ;
    
id_assignment
    : id ASSIGN expr {
        $$ = install_symbol($1);
        int index = look_up_symbol($1);
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    sw t0, %d(s0)\n", table[index].offset * (-4) - 48);
        fprintf(f_asm, "    addi sp, sp, -4\n");

    }
    | id { 
        $$ = install_symbol($1);
        int index = look_up_symbol($1);
        fprintf(f_asm, "    addi sp, sp, -4\n");
        fprintf(f_asm, "    sw zero, %d(s0)\n", table[index].offset * (-4) - 48);
    }
    ;



/*******ARRAY DECLARATION********/

array_decl
    : type arrays SEMICOLON {

    }
    ;

arrays
    : arrays COMMA array_id {

    }
    | array_id {

    }
    ;

array_id
    : id array_dim { 
        $$ = install_array_symbol($1,$2); 
    }
    ;

array_dim
    : array_dim LSQBRACK literal RSQBRACK { 
        //simplify the rule as this is the only case
        $$ = $3;
    }
    | LSQBRACK literal RSQBRACK{}
    ;

/*******FUNCTION DECLARATION********/

funtion_decl 
    : type id LPAREN params RPAREN SEMICOLON {
        fprintf(f_asm, ".global %s\n", $2);

    }
    | type id LPAREN RPAREN SEMICOLON {
        fprintf(f_asm, ".global %s\n", $2);
    }
    ;

params
    : params COMMA param{    

     }
    | param { }
    ;

param
    : type id {

    }
    ;


/*********  FUNCTION DEFINITION  ************/

function_def
    : type id LPAREN params RPAREN {
        cur_scope++;
        set_scope_and_offset_of_param($4);
        code_gen_func_header($2);

    }
    compound_stmt {
        pop_up_symbol(cur_scope);
        cur_scope--;
        code_gen_at_end_of_function_body($2);
    }
    | type id LPAREN RPAREN {
        cur_scope++;
        code_gen_func_header($2);
    }
    compound_stmt {
        pop_up_symbol(cur_scope);
        cur_scope--;
        code_gen_at_end_of_function_body($2);
    }
    ;



/*********STATEMENT****************/
stmts
    : stmts stmt {

    }
    | stmt { }
    ;
stmt
    : assign_expr SEMICOLON {

    }
    | if_else_stmt { }
    | switch_stmt {  }
    | while_stmt { }
    | for_stmt {}
    | return_stmt { }
    | BREAK SEMICOLON {

    } 
    | CONTINUE SEMICOLON {

    }
    | compound_stmt {

    }
    ;

if_else_stmt
    : IF LPAREN assign_expr RPAREN compound_stmt {

    }
    | IF LPAREN assign_expr RPAREN compound_stmt ELSE compound_stmt {

    }
    ;


switch_stmt
    : SWITCH LPAREN assign_expr RPAREN LCURLYBRACE switch_clauses RCURLYBRACE {

    }
    | SWITCH LPAREN assign_expr RPAREN LCURLYBRACE RCURLYBRACE{

    }
    ;

switch_clauses
    : switch_clauses switch_clause {

    }
    | switch_clause {

    }
    ;

switch_clause:
    CASE assign_expr COLON stmts {

    }
    | DEFAULT COLON stmts {

    }
    | CASE assign_expr COLON {

    }
    | DEFAULT COLON {

    }
    ;
while_stmt
    : WHILE LPAREN assign_expr RPAREN stmt {

    }
    | DO stmt WHILE LPAREN assign_expr RPAREN SEMICOLON {

    }
    ;

for_stmt
    : FOR LPAREN for_condition for_condition for_last_condition stmt {

    }
    ;
for_condition
    :/* id_assignment SEMICOLON { //i=0;
        char *s = (char*)malloc(sizeof(char)*(strlen($1)+2));
        strcpy(s, $1);
        strcat(s, ";");
        $$ = s;
    }
    
    |*/ type assign_expr SEMICOLON {    //int i=0;

    }
    | assign_expr SEMICOLON {
    }
    | SEMICOLON {
    }
    ;
for_last_condition
    : assign_expr RPAREN {
    }
    | RPAREN {
    }
    ;

return_stmt
    : RETURN assign_expr SEMICOLON {
    }
    | RETURN SEMICOLON {
    }
    ; 

compound_stmt  
    : LCURLYBRACE comp_stmt_content RCURLYBRACE { // 0 or more stmts
      
    }
    | LCURLYBRACE RCURLYBRACE{
       
    }
    ;

comp_stmt_content
    : stmt {
      
    }
    | stmt comp_stmt_content {
        
    }
    | declaration{
        
    }
    | declaration comp_stmt_content {}
    ;


/*********   EXPRESSION   ************/


assign_expr
    : ID ASSIGN assign_expr  {
        is_array = 0;
    }
    | ID LSQBRACK assign_expr RSQBRACK ASSIGN assign_expr{
        is_array = 0;
        fprintf(f_asm, "\n/*    normal assign*/\n");
        $$=$1;
        int index = look_up_symbol($1);
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    sw t0, %d(s0)\n", table[index].offset * (-4) - 48);
    }
    | ptr_assignee ASSIGN assign_expr{
        is_array = 0;
        if(assignflag==0){
            int index = look_up_symbol($1);
            fprintf(f_asm, "\n/*    pointer assign  */\n");
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, %d(s0)\n", table[index].offset * (-4) - 48);
            fprintf(f_asm, "    add t1, s0, t1\n");
            fprintf(f_asm, "    sw t0, 0(t1)\n");
        }else if(assignflag==2){
            fprintf(f_asm, "\n/*    array pointer assign*/\n");
            fprintf(f_asm, "    lw t0, 0(sp)\n") ;
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    add t1, s0, t1\n");
            fprintf(f_asm, "    sw t0, 0(t1)\n");
        }
    }
    | expr { 
        is_array = 0;
        $$=$1;
         }
    ;
ptr_assignee
    : STAR ID{
        is_array = 0;
        assignflag=0;
        $$ = $2;
    }
    | STAR LPAREN assign_expr RPAREN{
        is_array = 0;
        assignflag=2;
        $$=$3;

    }
    ;

expr
    : expr OROR term {
    }
    | term {  $$ = $1;  }
    ;
term
    : term ANDAND bitwise_or_expr {
    }
    | bitwise_or_expr{  $$ = $1; }
    ;
bitwise_or_expr
    : bitwise_or_expr BITWISE_OR bitwise_xor_expr {
    }
    | bitwise_xor_expr { $$ = $1;}
    ;

bitwise_xor_expr
    : bitwise_xor_expr BITWISE_XOR bitwise_and_expr {
    }
    | bitwise_and_expr { $$ = $1;}
    ;

bitwise_and_expr
    : bitwise_and_expr AND factor {
    }
    | factor { $$ = $1;}
    ;


factor
    : factor EQ primary {
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    lw t1, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    bne t1, t0, L%d\n", cur_label);
    }
    | factor NOTEQ primary { 
        if (in_if == 1) {
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    beq t1, t0, L%d\n", cur_label);
        } else {
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    bne t1, t0, LXA\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
            fprintf(f_asm, "    li t0, 0\n");
            fprintf(f_asm, "    sw t0, 0(sp)\n");
            fprintf(f_asm, "    beq zero, zero, EXITXA\n");
            fprintf(f_asm, "LXA:\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
            fprintf(f_asm, "    li t0, 1\n");
            fprintf(f_asm, "    sw t0, 0(sp)\n");
            fprintf(f_asm, "EXITXA:\n");
        }

    }
    | factor LT primary {
         fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    lw t1, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        if(do_flag)fprintf(f_asm, "    bge t1, t0, L%d\n", cur_label-2);
        else fprintf(f_asm, "    bge t1, t0, L%d\n", cur_label);
    }
    | factor LTE primary {
    }
    | factor GT primary {
    }
    | factor GTE primary {
    }
    | primary { $$ = $1; }
    ;


primary
    : primary PLUS atom {
        if(is_array){
            int index = look_up_symbol($1);
            $$=$1;
            if(dbg)printf("HELLO %s\n",table[index].name);
            fprintf(f_asm, "\n/*array add*/\n");
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t2, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    li t1, %d\n", table[index].offset * (-4) - 48);
            fprintf(f_asm, "    li t3, 4\n");
            fprintf(f_asm, "    mul t0, t0, t3\n");
            fprintf(f_asm, "    sub t0, t1, t0\n");
            fprintf(f_asm, "    sw t0, -4(sp)\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
        }else {
            fprintf(f_asm, "\n/*normal add*/\n");
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    add t0, t0, t1\n");
            fprintf(f_asm, "    sw t0, -4(sp)\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
        }
    }
    | primary MINUS atom {
         if(is_array) {
            int index = look_up_symbol($1);
            $$=$1;
            if(dbg)printf("HELLO %s\n",table[index].name);
            fprintf(f_asm, "\n/*array sub*/\n");
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t2, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    li t3, 4\n");
            fprintf(f_asm, "    mul t0, t0, t3\n");
            fprintf(f_asm, "    add t0, t2, t0\n");
            fprintf(f_asm, "    sw t0, -4(sp)\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
        } else {
            fprintf(f_asm, "    lw t0, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    lw t1, 0(sp)\n");
            fprintf(f_asm, "    addi sp, sp, 4\n");
            fprintf(f_asm, "    sub t0, t1, t0\n");
            fprintf(f_asm, "    sw t0, -4(sp)\n");
            fprintf(f_asm, "    addi sp, sp, -4\n");
        }
    }
    | atom { $$ = $1;}
    ;

atom
    : atom STAR unary_expr {
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    lw t1, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    mul t0, t0, t1\n");
        fprintf(f_asm, "    sw t0, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");
    }
    | atom DIVIDE unary_expr {
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    lw t1, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    div t0, t1, t0\n");
        fprintf(f_asm, "    sw t0, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");

    }
    | atom MOD unary_expr {
    }
    | unary_expr { $$ = $1;}
    ;


unary_expr
    : NOT unary_expr {
    }
    | BITWISE_NOT unary_expr {

    }
    | PLUS unary_expr %prec UPLUS {
    }
    | STAR unary_expr %prec DEREF {
        fprintf(f_asm, "\n/*unary multiply*/\n");
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        /*section B*/
        fprintf(f_asm, "    add t0, t0, s0\n");
        fprintf(f_asm, "    lw t1, 0(t0)\n");
        fprintf(f_asm, "    sw t1, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");
    }
    | MINUS unary_expr %prec UMINUS {
        fprintf(f_asm, "    lw t0, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    sub t0, zero, t0\n");
        fprintf(f_asm, "    sw t0, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");
    }
    | AND unary_expr %prec ADDR_OF {
    }
    | LPAREN type RPAREN unary_expr {
    }
    | INC unary_expr {   
    }
    | DEC unary_expr {
    }
    | post_expr { $$=$1;  }
    ;


post_expr
    : post_expr INC %prec POSTFIX_INC {
        
    }
    | post_expr DEC %prec POSTFIX_DEC {

    }
    | post_expr LPAREN arg_list RPAREN {
    }
    | post_expr LPAREN RPAREN {
    }
    | paren_expr {$$=$1; }
    ;



arg_list
    : arg_list COMMA assign_expr {
    }
    | assign_expr { $$ = $1;}
    ;

paren_expr
    : LPAREN assign_expr COMMA assign_expr RPAREN { 
    }
    | LPAREN assign_expr RPAREN { 
    }
    | literal { }
    | var { $$=$1; }
    ;

literal
    : NUMBER {   
        $$=$1;
        fprintf(f_asm, "    li t0, %d\n", $1);
        fprintf(f_asm, "    sw t0, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");  
        }
    | DOUBLE {
    }
    | STRING {
    }
    | CHAR {
    }
    ;


var
    : ID {
        fprintf(f_asm, "\n/*    ID*/\n");
        $$=$1;
        int index = look_up_symbol($1);
        if(table[index].type == T_POINTER)is_array=1;
        if(in_while==0){
            if (table[index].mode == LOCAL_MODE) {
                fprintf(f_asm, "    lw t0, %d(s0)\n", table[index].offset * (-4) - 48);
                fprintf(f_asm, "    sw t0, -4(sp)\n");
                fprintf(f_asm, "    addi sp, sp, -4\n");
            } else {
                /*fprintf(f_asm, "    lw t0, %d(sp)\n", table[index].offset * (-4) - 16);
                fprintf(f_asm, "    sw t0, -4(sp)\n");
                fprintf(f_asm, "    addi sp, sp, -4\n");*/
            }
        }else {
            fprintf(f_asm, "    lw t0, %d(s0)\n", table[index].offset * (-4) - 48);
            fprintf(f_asm, "    li t1, 0\n");
            fprintf(f_asm, "    beq t1, t0, L%d\n", cur_label);
        }


    }
    | non_ptr_array_id{
    }    
    ;


non_ptr_array_id
    : ID LSQBRACK assign_expr RSQBRACK{ 
        int index = look_up_symbol($1);
        fprintf(f_asm, "    li t0, %d\n", table[index].offset * (-4) - 48);
        fprintf(f_asm, "    lw t1, 0(sp)\n");
        fprintf(f_asm, "    addi sp, sp, 4\n");
        fprintf(f_asm, "    li t2, 4\n");
        fprintf(f_asm, "    mul t1, t1, t2\n");
        fprintf(f_asm, "    sub t0, t0, t1\n");
        fprintf(f_asm, "    add t0, s0, t0\n");
        fprintf(f_asm, "    lw t1, 0(t0)\n");
        fprintf(f_asm, "    sw t1, -4(sp)\n");
        fprintf(f_asm, "    addi sp, sp, -4\n");
    } 
    ;


/*****BASIC COMPONENTS*****/
type
    : TYPE { }
    ;

id
    : ID { $$=$1; }
    | STAR ID { $$ = $2; }
    ;




%%

int main(void) {
    yyparse();
    return 0;
}

void yyerror(char *msg) {
    fprintf(stderr, "Error at line %d: %s\n", lineNum, msg);
}