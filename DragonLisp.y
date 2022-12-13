%require  "3.8.2"
%debug

%defines
%define api.namespace { DragonLisp }
%define api.parser.class { DLParser }

%code requires {

#include <typeinfo>

#include "token.h"
#include "AST.h"

namespace DragonLisp {
    class DLDriver;
    class DLScanner;
}

}

%parse-param { DLScanner& scanner }

%param { DLDriver& drv }

%code {

#include <cstdio>
#include <cstdint>
#include <iostream>

#include "DragonLispDriver.h"

#undef yylex
#define yylex scanner.yylex

}

%locations
%define api.token.prefix {TOKEN_}
%define api.value.type variant
%define parse.assert

%token
    LESS_EQUAL		"<="
    GREATER_EQUAL	">="
    LESS		"<"
    GREATER		">"
    NOT_EQUAL		"/="
    EQUAL		"="
    LPAREN		"("
    RPAREN		")"
    PLUS		"+"
    MINUS		"-"
    MULTIPLY		"*"
    DIVIDE		"/"
    SPACE
    AND			"and"
    OR			"or"
    NOT			"not"
    MAX			"max"
    MIN			"min"
    IF			"if"
    LOGAND		"logand"
    LOGIOR		"logior"
    LOGXOR		"logxor"
    LOGNOR		"lognor"
    LOGEQV		"logeqv"
    MOD			"mod"
    REM			"rem"
    INCF		"incf"
    DECF		"decf"
    DEFVAR		"defvar"
    DEFUN		"defun"
    PRINT		"print"
    LOOP		"loop"
    SETQ		"setq"
    SETF		"setf"
    QUOTE		"quote"
    FOR			"for"
    IN			"in"
    FROM		"from"
    TO			"to"
    DOTIMES		"dotimes"
    DOLIST		"dolist"
    DO			"do"
    AREF		"aref"
    T			"t"
    NIL			"nil"
    RETURN		"return"
    MAKE_ARRAY		"make-array"
    DEFCONSTANT		"defconstant"
;

%token END              0 "EOF"
%token <double>		FLOAT		"float"
%token <int64_t>        INTEGER		"integer"
%token <std::string>    STRING		"string"
%token <std::string>    IDENTIFIER	"identifier"

%type <DragonLisp::Token>	var-op-tokens
%type <DragonLisp::Token>	lval-op-tokens
%type <DragonLisp::Token>	unary-tokens
%type <DragonLisp::Token>	binary-tokens
%type <DragonLisp::Token>	list-tokens

%type <std::shared_ptr<DragonLisp::LValueAST>>	L-Value
%type <std::shared_ptr<DragonLisp::LValueAST>>	array-ref
%type <std::shared_ptr<DragonLisp::FuncDefAST>>	func-def

%type <std::shared_ptr<DragonLisp::ExprAST>>	R-Value
%type <std::shared_ptr<DragonLisp::ExprAST>>	S-Expr
%type <std::shared_ptr<DragonLisp::ExprAST>>	S-Expr-helper

%type <std::vector<std::shared_ptr<DragonLisp::ExprAST>>>	R-Value-list

%type <std::vector<std::string>>				identifier-list
%type <std::vector<std::string>>				func-arg-list
%type <std::vector<std::shared_ptr<DragonLisp::ExprAST>>>	func-body
%type <std::shared_ptr<DragonLisp::ExprAST>>			func-body-expr

%type <std::shared_ptr<DragonLisp::ReturnAST>>	return-expr
%type <std::shared_ptr<DragonLisp::BinaryAST>>	S-Expr-binary
%type <std::shared_ptr<DragonLisp::UnaryAST>>	S-Expr-unary
%type <std::shared_ptr<DragonLisp::ListAST>>	S-Expr-list
%type <std::shared_ptr<DragonLisp::IfAST>>	S-Expr-if
%type <std::shared_ptr<DragonLisp::VarOpAST>>	S-Expr-var-op
%type <std::shared_ptr<DragonLisp::LValOpAST>>	S-Expr-Lval-op
%type <std::shared_ptr<DragonLisp::LoopAST>>	S-Expr-loop
%type <std::shared_ptr<DragonLisp::FuncCallAST>>	S-Expr-func-call


%type <std::variant<std::shared_ptr<DragonLisp::ExprAST>, std::shared_ptr<DragonLisp::FuncDefAST>>>			statement

%define parse.error verbose

%start S

%%

S
	: END			{ std::printf("Parsed S -> END\n"); }
	| statements END	{ std::printf("Parsed S -> statements END\n"); }
;

statements
	: statement		{ std::printf("Parsed statements -> statement\n"); drv.execute($1); }
	| statements statement	{ std::printf("Parsed statements -> statements statement\n"); drv.execute($2); }
;

statement
	: R-Value		{ std::printf("Parsed statement -> R-Value\n"); $$ = $1; }
	| func-def		{ std::printf("Parsed statement -> func-def\n"); $$ = $1; }
;

array-ref
	: LPAREN AREF IDENTIFIER R-Value RPAREN	{ std::printf("Parsed array-ref -> ( AREF IDENTIFIER R-Value )\n"); $$ = drv.constructLValueAST($3, $4); }
;

return-expr
	: LPAREN RETURN R-Value RPAREN	{ std::printf("Parsed return-expr -> ( RETURN R-Value )\n"); $$ = drv.constructReturnAST($3); }
;

func-body-expr
	: return-expr		{ std::printf("Parsed func-body -> return-expr\n"); $$ = $1; }
	| R-Value		{ std::printf("Parsed func-body -> R-Value\n"); $$ = $1; }
;

func-body
	: func-body-expr		{ std::printf("Parsed func-body -> func-body-expr\n"); $$ = { $1 }; }
	| func-body func-body-expr	{ std::printf("Parsed func-body -> func-body func-body-expr\n"); $1.push_back($2); $$ = $1; }
;

L-Value
	: IDENTIFIER	{ std::printf("Parsed L-Value -> IDENTIFIER\n"); $$ = drv.constructLValueAST($1); }
	| array-ref	{ std::printf("Parsed L-Value -> array-ref\n"); $$ = $1; }
;

R-Value
	: IDENTIFIER	{ std::printf("Parsed R-Value -> IDENTIFIER\n"); $$ = drv.constructLValueAST($1); }
	| S-Expr	{ std::printf("Parsed R-Value -> S-Expr\n"); $$ = $1; }
	| INTEGER	{ std::printf("Parsed R-Value -> INTEGER\n"); $$ = drv.constructLiteralAST($1); }
	| FLOAT		{ std::printf("Parsed R-Value -> FLOAT\n"); $$ = drv.constructLiteralAST($1); }
	| STRING	{ std::printf("Parsed R-Value -> STRING\n"); $$ = drv.constructLiteralAST($1); }
	| array-ref	{ std::printf("Parsed R-Value -> array-ref\n"); $$ = $1; }
	| NIL		{ std::printf("Parsed R-Value -> NIL\n"); $$ = drv.constructLiteralAST(false); }
	| T		{ std::printf("Parsed R-Value -> T\n"); $$ = drv.constructLiteralAST(true); }
;

R-Value-list
	: R-Value		{ std::printf("Parsed R-Value-list -> R-Value\n"); $$ = { $1 }; }
	| R-Value-list R-Value	{ std::printf("Parsed R-Value-list -> R-Value-list R-Value\n"); $1.push_back($2); $$ = $1; }
;

S-Expr
	: LPAREN S-Expr-helper RPAREN	{ std::printf("Parsed S-Expr -> ( S-Expr-helper )\n"); $$ = $2; }
	| LPAREN RPAREN			{ std::printf("Parsed S-Expr -> ()\n"); $$ = drv.constructLiteralAST(false); }
;

S-Expr-helper
	: S-Expr-var-op		{ std::printf("Parsed S-Expr-helper -> S-Expr-var-op\n"); $$ = $1; }
	| S-Expr-Lval-op	{ std::printf("Parsed S-Expr-helper -> S-Expr-Lval-op\n"); $$ = $1; }
	| S-Expr-unary		{ std::printf("Parsed S-Expr-helper -> S-Expr-unary\n"); $$ = $1; }
	| S-Expr-binary		{ std::printf("Parsed S-Expr-helper -> S-Expr-binary\n"); $$ = $1; }
	| S-Expr-list		{ std::printf("Parsed S-Expr-helper -> S-Expr-list\n"); $$ = $1; }
	| S-Expr-if		{ std::printf("Parsed S-Expr-helper -> S-Expr-if\n"); $$ = $1; }
	| S-Expr-loop		{ std::printf("Parsed S-Expr-helper -> S-Expr-loop\n"); $$ = $1; }
	| S-Expr-func-call	{ std::printf("Parsed S-Expr-helper -> S-Expr-func-call\n"); $$ = $1; }
;

S-Expr-var-op
	: var-op-tokens IDENTIFIER R-Value	{ std::printf("Parsed S-Expr-var-op -> var-op-tokens IDENTIFIER R-Value\n"); $$ = drv.constructVarOpAST($2, $3, $1); }
;

var-op-tokens
	: DEFVAR	{ std::printf("Parsed var-op-tokens -> DEFVAR\n"); $$ = DragonLisp::Token::DEFVAR; }
	| SETQ		{ std::printf("Parsed var-op-tokens -> SETQ\n"); $$ = DragonLisp::Token::SETQ; }
;

S-Expr-Lval-op
	: lval-op-tokens L-Value R-Value	{ std::printf("Parsed S-Expr-Lval-op -> lval-op-tokens L-Value R-Value\n"); $$ = drv.constructLValOpAST($2, $3, $1); }
;

lval-op-tokens
	: SETF	{ std::printf("Parsed lval-op-tokens -> SETF\n"); $$ = DragonLisp::Token::SETF; }
	| INCF	{ std::printf("Parsed lval-op-tokens -> INCF\n"); $$ = DragonLisp::Token::INCF; }
	| DECF	{ std::printf("Parsed lval-op-tokens -> DECF\n"); $$ = DragonLisp::Token::DECF; }
;

S-Expr-unary
	: unary-tokens R-Value	{ std::printf("Parsed S-Expr-unary -> unary-tokens R-Value\n"); $$ = drv.constructUnaryExprAST($2, $1); }
;

unary-tokens
	: NOT		{ std::printf("Parsed unary-tokens -> NOT\n"); $$ = DragonLisp::Token::NOT; }
	| PRINT		{ std::printf("Parsed unary-tokens -> PRINT\n"); $$ = DragonLisp::Token::PRINT; }
	| MAKE_ARRAY	{ std::printf("Parsed unary-tokens -> MAKE_ARRAY\n"); $$ = DragonLisp::Token::MAKE_ARRAY; }
;

S-Expr-binary
	: binary-tokens R-Value R-Value	{ std::printf("Parsed S-Expr-binary -> binary-tokens R-Value R-Value\n"); $$ = drv.constructBinaryExprAST($2, $3, $1); }
;

binary-tokens
	: LESS		{ std::printf("Parsed binary-tokens -> LESS\n"); $$ = DragonLisp::Token::LESS; }
	| LESS_EQUAL	{ std::printf("Parsed binary-tokens -> LESS_EQUAL\n"); $$ = DragonLisp::Token::LESS_EQUAL; }
	| GREATER	{ std::printf("Parsed binary-tokens -> GREATER\n"); $$ = DragonLisp::Token::GREATER; }
	| GREATER_EQUAL	{ std::printf("Parsed binary-tokens -> GREATER_EQUAL\n"); $$ = DragonLisp::Token::GREATER_EQUAL; }
	| LOGNOR	{ std::printf("Parsed binary-tokens -> LOGNOR\n"); $$ = DragonLisp::Token::LOGNOR; }
	| MOD		{ std::printf("Parsed binary-tokens -> MOD\n"); $$ = DragonLisp::Token::MOD; }
	| REM		{ std::printf("Parsed binary-tokens -> REM\n"); $$ = DragonLisp::Token::MOD; /* This is the same as MOD. */ }
;

S-Expr-list
	: list-tokens R-Value-list	{ std::printf("Parsed S-Expr-list -> list-tokens R-Value-list\n"); $$ = drv.constructListExprAST($2, $1); }
;

list-tokens
	: EQUAL		{ std::printf("Parsed list-tokens -> EQUAL\n"); $$ = DragonLisp::Token::EQUAL; }
	| NOT_EQUAL	{ std::printf("Parsed list-tokens -> NOT_EQUAL\n"); $$ = DragonLisp::Token::NOT_EQUAL; }
	| AND		{ std::printf("Parsed list-tokens -> AND\n"); $$ = DragonLisp::Token::AND; }
	| OR		{ std::printf("Parsed list-tokens -> OR\n"); $$ = DragonLisp::Token::OR; }
	| MAX		{ std::printf("Parsed list-tokens -> MAX\n"); $$ = DragonLisp::Token::MAX; }
	| MIN		{ std::printf("Parsed list-tokens -> MIN\n"); $$ = DragonLisp::Token::MIN; }
	| LOGAND	{ std::printf("Parsed list-tokens -> LOGAND\n"); $$ = DragonLisp::Token::LOGAND; }
	| LOGIOR	{ std::printf("Parsed list-tokens -> LOGIOR\n"); $$ = DragonLisp::Token::LOGIOR; }
	| LOGXOR	{ std::printf("Parsed list-tokens -> LOGXOR\n"); $$ = DragonLisp::Token::LOGXOR; }
	| LOGEQV	{ std::printf("Parsed list-tokens -> LOGEQV\n"); $$ = DragonLisp::Token::LOGEQV; }
	| PLUS		{ std::printf("Parsed list-tokens -> PLUS\n"); $$ = DragonLisp::Token::PLUS; }
	| MINUS		{ std::printf("Parsed list-tokens -> MINUS\n"); $$ = DragonLisp::Token::MINUS; }
	| MULTIPLY	{ std::printf("Parsed list-tokens -> MULTIPLY\n"); $$ = DragonLisp::Token::MULTIPLY; }
	| DIVIDE	{ std::printf("Parsed list-tokens -> DIVIDE\n"); $$ = DragonLisp::Token::DIVIDE; }
;

S-Expr-if
	: IF R-Value func-body-expr func-body-expr	{ std::printf("Parsed S-Expr-if -> IF R-Value func-body-expr func-body-expr\n"); $$ = drv.constructIfAST($2, $3, $4); }
	| IF R-Value func-body-expr			{ std::printf("Parsed S-Expr-if -> IF R-Value func-body-expr\n"); $$ = drv.constructIfAST($2, $3, nullptr); }
;

S-Expr-loop
	: LOOP func-body						{ std::printf("Parsed S-Expr-loop -> LOOP func-body\n"); $$ = drv.constructLoopAST($2); }
	| LOOP FOR IDENTIFIER FROM R-Value TO R-Value DO func-body	{ std::printf("Parsed S-Expr-loop -> LOOP FOR IDENTIFIER FROM R-Value TO R-Value DO func-body\n"); $$ = drv.constructLoopAST($3, $5, $7, $9); }
	| DOTIMES LPAREN IDENTIFIER R-Value RPAREN func-body		{ std::printf("Parsed S-Expr-loop -> DOTIMES LPAREN IDENTIFIER R-Value RPAREN func-body\n"); $$ = drv.constructLoopAST($3, $4, $6); }
;

func-def
	: LPAREN DEFUN IDENTIFIER func-arg-list func-body RPAREN	{ std::printf("Parsed func-def -> ( DEFUN IDENTIFIER func-arg-list func-body )\n"); $$ = drv.constructFuncDefAST($3, $4, $5); }
;

func-arg-list
	: LPAREN RPAREN			{ std::printf("Parsed func-arg-list -> ( )\n"); $$ = {}; }
	| LPAREN identifier-list RPAREN	{ std::printf("Parsed func-arg-list -> ( identifier-list )\n"); $$ = $2; }

identifier-list
	: identifier-list IDENTIFIER	{ std::printf("Parsed identifier-list -> identifier-list IDENTIFIER\n"); $1.push_back($2); $$ = $1; }
	| IDENTIFIER			{ std::printf("Parsed identifier-list -> IDENTIFIER\n"); $$ = { $1 }; }
;

S-Expr-func-call
	: IDENTIFIER R-Value-list	{ std::printf("Parsed S-Expr-func-call -> IDENTIFIER R-Value-list\n"); $$ = drv.constructFuncCallAST($1, $2); }
	| IDENTIFIER			{ std::printf("Parsed S-Expr-func-call -> IDENTIFIER\n"); $$ = drv.constructFuncCallAST($1, {}); }
;

%%

void DragonLisp::DLParser::error(const location_type& l, const std::string& msg) {
    std::cerr << "Error: " << msg << " at " << l << "\n";
}
