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
    QUOTE		"quote"
    FOR			"for"
    IN			"in"
    FROM		"from"
    TO			"to"
    DOTIMES		"dotimes"
    DOLIST		"dolist"
    DO			"do"
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
	: END
	| S-Exprs END
;

S-Exprs
	: S-Exprs empty S-Expr
	| S-Expr
;

spaces
	: SPACE
	| spaces SPACE
;

empty
	:
	| spaces
;

R-Value
	: IDENTIFIER
	| literal
	| S-Expr

S-Expr
	: LPAREN empty S-Expr-helper empty RPAREN
	| LPAREN empty RPAREN
;

literal
	: INTEGER
	| FLOAT
	| STRING
;

S-Expr-helper
	: S-Expr-var-op
	| S-Expr-unary
	| S-Expr-binary
	| S-Expr-list
	| S-Expr-if
	| S-Expr-loop
	| S-Expr-func-def
	| S-Expr-func-call
;

S-Expr-var-op
	: var-op-tokens spaces IDENTIFIER spaces R-Value
;

var-op-tokens
	: DEFVAR
	| SETQ
	| INCF
	| DECF
	| DEFCONSTANT
;

S-Expr-unary
	: unary-tokens spaces R-Value
;

unary-tokens
	: NOT
	| PRINT
;

S-Expr-binary
	: binary-tokens spaces S-Expr empty S-Expr
;

binary-tokens
	: LESS
	| LESS_EQUAL
	| GREATER
	| GREATER_EQUAL
	| LOGNOR
	| MOD
	| REM
;

S-Expr-list
	: list-tokens spaces S-Exprs
;

list-tokens
	: EQUAL
	| NOT_EQUAL
	| AND
	| OR
	| MAX
	| MIN
	| LOGAND
	| LOGIOR
	| LOGXOR
	| LOGEQV
	| PLUS
	| MINUS
	| MULTIPLY
	| DIVIDE
;

S-Expr-if
	: IF spaces S-Expr empty S-Expr empty S-Expr
;

S-Expr-loop
	: LOOP empty S-Exprs
	| LOOP spaces FOR spaces IDENTIFIER spaces IN empty S-Expr empty DO empty S-Exprs
	| LOOP spaces FOR spaces IDENTIFIER spaces FROM empty S-Expr empty TO empty S-Expr empty DO empty S-Exprs
	| DOTIMES empty LPAREN empty IDENTIFIER empty S-Expr empty RPAREN empty S-Exprs
	| DOLIST empty LPAREN empty IDENTIFIER empty S-Expr empty RPAREN empty S-Exprs
;

S-Expr-func-def
	: DEFUN spaces IDENTIFIER empty LPAREN empty identifier-list empty RPAREN ignored-func-doc S-Exprs
;

ignored-func-doc
	: empty STRING empty
;

identifier-list
	: identifier-list IDENTIFIER
	| IDENTIFIER
;

%%

void DragonLisp::DLParser::error(const location_type& l, const std::string& msg) {
    std::cerr << "Error: " << msg << " at " << l << "\n";
}
