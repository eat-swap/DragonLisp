%require  "3.8.2"
%debug

%defines
%define api.namespace { DragonLisp }
%define api.parser.class { DLParser }

%code requires {

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
    LPAREN  "("
    RPAREN  ")"
    PLUS    "+"
    MINUS   "-"
    STAR    "*"
    SLASH   "/"
;

%token END 0 "EOF"
%token <int64_t> NUMBER "number"

%define parse.error verbose

%%

S
    : R END

R
    :
    | R S-Expr

S-Expr
    : LPAREN operator NUMBER NUMBER RPAREN { std::printf("This is S-Expr!\n"); }

operator
    : PLUS  { std::printf("I am plus +\n"); }
    | MINUS { std::printf("I am minus -\n"); }
    | STAR  { std::printf("I am star *\n"); }
    | SLASH { std::printf("I am slash /\n"); }

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
