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

%%

void DragonLisp::DLParser::error(const location_type& l, const std::string& msg) {
    std::cerr << "Error: " << msg << " at " << l << "\n";
}
