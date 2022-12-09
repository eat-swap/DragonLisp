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
    LE	    "<="
    GE	    ">="
    EQUAL   "="
    NE	    "/="
    LT	    "<"
    GT	    ">"
    LPAREN  "("
    RPAREN  ")"
    PLUS    "+"
    MINUS   "-"
    STAR    "*"
    SLASH   "/"
;

%token END 0 "EOF"
%token <int64_t> NUMBER "number"

%type <DragonLisp::Token> basic_operator
%type <DragonLisp::Token> arithmetic_operator
%type <DragonLisp::Token> comparsion_operator

%define parse.error verbose

%%

S
    : R END

R
    :
    | R S-Expr

S-Expr
    : LPAREN basic_operator NUMBER NUMBER RPAREN {
        std::printf("Operator -> %d, LHS -> %lld, RHS -> %lld\n", int($2), $3, $4);
        std::printf("This is S-Expr!\n");
    }
;

basic_operator
    : arithmetic_operator   { $$ = $1; }
    | boolean_operator      { $$ = $1; }
    | comparsion_operator   { $$ = $1; }
;

arithmetic_operator
    : PLUS  { $$ = Token::PLUS; std::printf("I am plus +\n"); }
    | MINUS { $$ = Token::MINUS; std::printf("I am minus -\n"); }
    | STAR  { $$ = Token::MULTIPLY; std::printf("I am star *\n"); }
    | SLASH { $$ = Token::DIVIDE; std::printf("I am slash /\n"); }
;

boolean_operator
    :
;

comparsion_operator
    : LE    { $$ = Token::LE; }
    | LT    { $$ = Token::LT; }
    | GE    { $$ = Token::GE; }
    | GT    { $$ = Token::GT; }
    | EQUAL { $$ = Token::EQUAL; }
    | NE    { $$ = Token::NE; }

%%

void DragonLisp::DLParser::error(const location_type& l, const std::string& msg) {
    std::cerr << "Error: " << msg << " at " << l << "\n";
}

DragonLisp::DLParser::symbol_type make_NUMBER(const std::string& s, const DragonLisp::DLParser::location_type& loc) {
    try {
        int n = std::stoi(s);
        return DragonLisp::DLParser::make_NUMBER(n, loc);
    } catch (...) {
        throw DragonLisp::DLParser::syntax_error(loc, "Invalid integer provided: " + s);
    }
}
