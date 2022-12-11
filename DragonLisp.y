%require  "3.8.2"
%debug

%defines
%define api.namespace { DragonLisp }
%define api.parser.class { DLParser }

%code requires {

#include <typeinfo>

#include "token.h"

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

#include "DragonLispDriver.hh"

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
    MAKE_ARRAY		"make-array"
    DEFCONSTANT		"defconstant"
;

%token END              0 "EOF"
%token <double>		FLOAT		"float"
%token <int64_t>        INTEGER		"integer"
%token <std::string>    STRING		"string"
%token <std::string>    IDENTIFIER	"identifier"

%define parse.error verbose

%%

S
	: END			{ std::printf("Parsed S -> END\n"); }
	| statements END	{ std::printf("Parsed S -> statements END\n"); }
;

statements
	: statement		{ std::printf("Parsed statements -> statement\n"); }
	| statements statement	{ std::printf("Parsed statements -> statements statement\n"); }
;

statement
	: S-Expr		{ std::printf("Parsed statement -> S-Expr\n"); }
	| func-def		{ std::printf("Parsed statement -> func-def\n"); }
;

S-Exprs
	: S-Exprs S-Expr	{ std::printf("Parsed S-Exprs -> S-Exprs S-Expr\n"); }
	| S-Expr		{ std::printf("Parsed S-Exprs -> S-Expr\n"); }
;

array-ref
	: LPAREN AREF IDENTIFIER R-Value RPAREN	{ std::printf("Parsed array-ref -> ( AREF IDENTIFIER R-Value )\n"); }
;

L-Value
	: IDENTIFIER
	| array-ref

R-Value
	: IDENTIFIER	{ std::printf("Parsed R-Value -> IDENTIFIER\n"); }
	| S-Expr	{ std::printf("Parsed R-Value -> S-Expr\n"); }
	| INTEGER	{ std::printf("Parsed R-Value -> INTEGER\n"); }
	| FLOAT		{ std::printf("Parsed R-Value -> FLOAT\n"); }
	| STRING	{ std::printf("Parsed R-Value -> STRING\n"); }
;

R-Value-list
	: R-Value		{ std::printf("Parsed R-Value-list -> R-Value\n"); }
	| R-Value-list R-Value	{ std::printf("Parsed R-Value-list -> R-Value-list R-Value\n"); }
;

S-Expr
	: LPAREN S-Expr-helper RPAREN	{ std::printf("Parsed S-Expr -> ( S-Expr-helper )\n"); }
	| LPAREN RPAREN			{ std::printf("Parsed S-Expr -> ()\n"); }
;

S-Expr-helper
	: S-Expr-var-op		{ std::printf("Parsed S-Expr-helper -> S-Expr-var-op\n"); }
	| S-Expr-Lval-op	{ std::printf("Parsed S-Expr-helper -> S-Expr-Lval-op\n"); }
	| S-Expr-unary		{ std::printf("Parsed S-Expr-helper -> S-Expr-unary\n"); }
	| S-Expr-binary		{ std::printf("Parsed S-Expr-helper -> S-Expr-binary\n"); }
	| S-Expr-list		{ std::printf("Parsed S-Expr-helper -> S-Expr-list\n"); }
	| S-Expr-if		{ std::printf("Parsed S-Expr-helper -> S-Expr-if\n"); }
	| S-Expr-loop		{ std::printf("Parsed S-Expr-helper -> S-Expr-loop\n"); }
	| S-Expr-func-call	{ std::printf("Parsed S-Expr-helper -> S-Expr-func-call\n"); }
;

S-Expr-var-op
	: var-op-tokens IDENTIFIER R-Value	{ std::printf("Parsed S-Expr-var-op -> var-op-tokens IDENTIFIER R-Value\n"); }
;

var-op-tokens
	: DEFVAR	{ std::printf("Parsed var-op-tokens -> DEFVAR\n"); }
	| SETQ		{ std::printf("Parsed var-op-tokens -> SETQ\n"); }
	| INCF		{ std::printf("Parsed var-op-tokens -> INCF\n"); }
	| DECF		{ std::printf("Parsed var-op-tokens -> DECF\n"); }
	| DEFCONSTANT	{ std::printf("Parsed var-op-tokens -> DEFCONSTANT\n"); }
;

S-Expr-Lval-op
	: lval-op-tokens L-Value R-Value	{ std::printf("Parsed S-Expr-Lval-op -> lval-op-tokens L-Value R-Value\n"); }
;

lval-op-tokens
	: SETF	{ std::printf("Parsed lval-op-tokens -> SETF\n"); }
	| INCF	{ std::printf("Parsed lval-op-tokens -> INCF\n"); }
	| DECF	{ std::printf("Parsed lval-op-tokens -> DECF\n"); }
;

S-Expr-unary
	: unary-tokens R-Value	{ std::printf("Parsed S-Expr-unary -> unary-tokens R-Value\n"); }
;

unary-tokens
	: NOT		{ std::printf("Parsed unary-tokens -> NOT\n"); }
	| PRINT		{ std::printf("Parsed unary-tokens -> PRINT\n"); }
	| MAKE_ARRAY	{ std::printf("Parsed unary-tokens -> MAKE_ARRAY\n"); }
;

S-Expr-binary
	: binary-tokens R-Value R-Value	{ std::printf("Parsed S-Expr-binary -> binary-tokens R-Value R-Value\n"); }
;

binary-tokens
	: LESS		{ std::printf("Parsed binary-tokens -> LESS\n"); }
	| LESS_EQUAL	{ std::printf("Parsed binary-tokens -> LESS_EQUAL\n"); }
	| GREATER	{ std::printf("Parsed binary-tokens -> GREATER\n"); }
	| GREATER_EQUAL	{ std::printf("Parsed binary-tokens -> GREATER_EQUAL\n"); }
	| LOGNOR	{ std::printf("Parsed binary-tokens -> LOGNOR\n"); }
	| MOD		{ std::printf("Parsed binary-tokens -> MOD\n"); }
	| REM		{ std::printf("Parsed binary-tokens -> REM\n"); }
;

S-Expr-list
	: list-tokens R-Value-list	{ std::printf("Parsed S-Expr-list -> list-tokens R-Value-list\n"); }
;

list-tokens
	: EQUAL		{ std::printf("Parsed list-tokens -> EQUAL\n"); }
	| NOT_EQUAL	{ std::printf("Parsed list-tokens -> NOT_EQUAL\n"); }
	| AND		{ std::printf("Parsed list-tokens -> AND\n"); }
	| OR		{ std::printf("Parsed list-tokens -> OR\n"); }
	| MAX		{ std::printf("Parsed list-tokens -> MAX\n"); }
	| MIN		{ std::printf("Parsed list-tokens -> MIN\n"); }
	| LOGAND	{ std::printf("Parsed list-tokens -> LOGAND\n"); }
	| LOGIOR	{ std::printf("Parsed list-tokens -> LOGIOR\n"); }
	| LOGXOR	{ std::printf("Parsed list-tokens -> LOGXOR\n"); }
	| LOGEQV	{ std::printf("Parsed list-tokens -> LOGEQV\n"); }
	| PLUS		{ std::printf("Parsed list-tokens -> PLUS\n"); }
	| MINUS		{ std::printf("Parsed list-tokens -> MINUS\n"); }
	| MULTIPLY	{ std::printf("Parsed list-tokens -> MULTIPLY\n"); }
	| DIVIDE	{ std::printf("Parsed list-tokens -> DIVIDE\n"); }
;

S-Expr-if
	: IF R-Value R-Value R-Value	{ std::printf("Parsed S-Expr-if -> IF R-Value R-Value R-Value\n"); }
	| IF R-Value R-Value		{ std::printf("Parsed S-Expr-if -> IF R-Value R-Value\n"); }
;

S-Expr-loop
	: LOOP S-Exprs							{ std::printf("Parsed S-Expr-loop -> LOOP S-Exprs\n"); }
	| LOOP FOR IDENTIFIER FROM R-Value TO R-Value DO S-Exprs	{ std::printf("Parsed S-Expr-loop -> LOOP FOR IDENTIFIER FROM R-Value TO R-Value DO S-Exprs\n"); }
	| DOTIMES LPAREN IDENTIFIER R-Value RPAREN S-Exprs		{ std::printf("Parsed S-Expr-loop -> DOTIMES LPAREN IDENTIFIER R-Value RPAREN S-Exprs\n"); }
;

func-def
	: LPAREN DEFUN IDENTIFIER LPAREN identifier-list RPAREN ignored-func-doc S-Exprs RPAREN	{ std::printf("Parsed func-def -> DEFUN IDENTIFIER ( identifier-list ) ignored-func-doc S-Exprs\n"); }
;

ignored-func-doc
	: %empty	{ std::printf("Parsed ignored-func-doc -> \n"); }
	| STRING	{ std::printf("Parsed ignored-func-doc -> STRING\n"); }
;

identifier-list
	: %empty			{ std::printf("Parsed identifier-list -> \n"); }
	| identifier-list IDENTIFIER	{ std::printf("Parsed identifier-list -> identifier-list IDENTIFIER\n"); }
	| IDENTIFIER			{ std::printf("Parsed identifier-list -> IDENTIFIER\n"); }
;

S-Expr-func-call
	: IDENTIFIER R-Value-list	{ std::printf("Parsed S-Expr-func-call -> IDENTIFIER R-Value-list\n"); }
;

%%

void DragonLisp::DLParser::error(const location_type& l, const std::string& msg) {
    std::cerr << "Error: " << msg << " at " << l << "\n";
}
