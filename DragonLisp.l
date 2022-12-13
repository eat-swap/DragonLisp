%{

#include <cstdio>
#include <cstdint>
#include <iostream>

#include "DragonLispScanner.h"

#undef YY_DECL
#define YY_DECL int DragonLisp::DLScanner::yylex(DragonLisp::DLParser::semantic_type* const lval, DragonLisp::DLParser::location_type* location, DragonLisp::DLDriver& drv)

using token = DragonLisp::DLParser::token;

#define yyterminate() return token::TOKEN_END;

#define YY_USER_ACTION loc->columns(yyleng);

#ifdef DLDEBUG
#define PRINT_FUNC std::printf
#else // DLDEBUG
template<typename T, typename... Ts>
void printNothing(T _ign1, Ts... _ign2) { ; }
template<typename T>
void printNothing(T _ign1) { ; }
#define PRINT_FUNC printNothing
#endif // DLDEBUG

%}

%option yyclass="DragonLisp::DLScanner"
%option verbose backup warn noyywrap c++ nounistd debug noline

float	[+-]?[0-9]*[.][0-9]+([eE][+-][0-9]+)?
int		[+-]?(0[xX][0-9A-Fa-f]*|0[0-7]*|[1-9][0-9]*)
id		[a-zA-Z_][a-zA-Z_0-9]*
blank	[ \t\v\r]
comment	;[^\n\r]*
string	\"(?:[^\"\\]|\\.)*\"

and		[aA][nN][dD]
or		[oO][rR]
not		[nN][oO][tT]
max		[mM][aA][xX]
min		[mM][iI][nN]
if		[iI][fF]
logand	[lL][oO][gG][aA][nN][dD]
logior	[lL][oO][gG][iI][oO][rR]
logxor	[lL][oO][gG][xX][oO][rR]
lognor	[lL][oO][gG][nN][oO][rR]
logeqv	[lL][oO][gG][eE][qQ][vV]
mod		[mM][oO][dD]
rem		[rR][eE][mM]
incf	[iI][nN][cC][fF]
decf	[dD][eE][cC][fF]
defvar	[dD][eE][fF][vV][aA][rR]
defun	[dD][eE][fF][uU][nN]
print	[pP][rR][iI][nN][tT]
loop	[lL][oO][oO][pP]
setq	[sS][eE][tT][qQ]
setf	[sS][eE][tT][fF]
quote	[qQ][uU][oO][tT][eE]
for		[fF][oO][rR]
in		[iI][nN]
from	[fF][rR][oO][mM]
to		[tT][oO]
dotimes	[dD][oO][tT][iI][mM][eE][sS]
dolist	[dD][oO][lL][iI][sS][tT]
do		[dD][oO]
aref	[aA][rR][eE][fF]
t		[tT]
nil		[nN][iI][lL]
return	[rR][eE][tT][uU][rR][nN]
returnfrom	[rR][eE][tT][uU][rR][nN][-][fF][rR][oO][mM]
makearray	[mM][aA][kK][eE][-][aA][rR][rR][aA][yY]
defconstant	[dD][eE][fF][cC][oO][nN][sS][tT][aA][nN][tT]

%%

%{
	yylval = lval;
%}

{blank}+	{
	loc->step();
	// PRINT_FUNC("Skipping blank\n");
	// return token::TOKEN_SPACE;
};

\n+		{
	loc->lines(yyleng);
	loc->step();
	// PRINT_FUNC("Skipping newline\n");
	// return token::TOKEN_SPACE;
}

{float}	{
	errno = 0;
	char* seq_end_ptr = nullptr;
	double n = strtod(yytext, &seq_end_ptr);
	if (errno == ERANGE)
		throw DragonLisp::DLParser::syntax_error(*loc, "Float out of range: " + std::string(yytext));
	if (seq_end_ptr - yytext < yyleng)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid float scanned: [" + std::string(yytext, seq_end_ptr) + "], but provided [" + std::string(yytext) + "]");
	yylval->emplace<double>(n);
	PRINT_FUNC("Scanned float: %lf\n", n);
	return token::TOKEN_FLOAT;
}

{int}	{
	errno = 0;
	char* seq_end_ptr = nullptr;
	int64_t n = strtoll(yytext, &seq_end_ptr, 0);
	if (errno == ERANGE)
		throw DragonLisp::DLParser::syntax_error(*loc, "Integer out of range: " + std::string(yytext));
	if (seq_end_ptr - yytext < yyleng)
		throw DragonLisp::DLParser::syntax_error(*loc, "Invalid integer scanned: [" + std::string(yytext, seq_end_ptr) + "], but provided [" + std::string(yytext) + "]");
	yylval->emplace<int64_t>(n);
	PRINT_FUNC("Scanned integer: %lld\n", n);
	return token::TOKEN_INTEGER;
};

"<="	{
	PRINT_FUNC("Scanned <=\n");
	return token::TOKEN_LESS_EQUAL;
};

">="	{
	PRINT_FUNC("Scanned >=\n");
	return token::TOKEN_GREATER_EQUAL;
};

"<"		{
	PRINT_FUNC("Scanned <\n");
	return token::TOKEN_LESS;
};

">"		{
	PRINT_FUNC("Scanned >\n");
	return token::TOKEN_GREATER;
};

"/="	{
	PRINT_FUNC("Scanned !=\n");
	return token::TOKEN_NOT_EQUAL;
};

"="		{
	PRINT_FUNC("Scanned =\n");
	return token::TOKEN_EQUAL;
};

"("		{
	PRINT_FUNC("Scanned (\n");
	return token::TOKEN_LPAREN;
};

")"		{
	PRINT_FUNC("Scanned )\n");
	return token::TOKEN_RPAREN;
};

"+"		{
	PRINT_FUNC("Scanned +\n");
	return token::TOKEN_PLUS;
};

"-"		{
	PRINT_FUNC("Scanned -\n");
	return token::TOKEN_MINUS;
};

"*"		{
	PRINT_FUNC("Scanned *\n");
	return token::TOKEN_MULTIPLY;
};

"/"		{
	PRINT_FUNC("Scanned /\n");
	return token::TOKEN_DIVIDE;
};

{and}	{
	PRINT_FUNC("Scanned and\n");
	return token::TOKEN_AND;
};

{or}	{
	PRINT_FUNC("Scanned or\n");
	return token::TOKEN_OR;
};

{not}	{
	PRINT_FUNC("Scanned not\n");
	return token::TOKEN_NOT;
};

{max}	{
	PRINT_FUNC("Scanned max\n");
	return token::TOKEN_MAX;
};

{min}	{
	PRINT_FUNC("Scanned min\n");
	return token::TOKEN_MIN;
};

{if}	{
	PRINT_FUNC("Scanned if\n");
	return token::TOKEN_IF;
};

{logand}	{
	PRINT_FUNC("Scanned logand\n");
	return token::TOKEN_LOGAND;
};

{logior}	{
	PRINT_FUNC("Scanned logior\n");
	return token::TOKEN_LOGIOR;
};

{logxor}	{
	PRINT_FUNC("Scanned logxor\n");
	return token::TOKEN_LOGXOR;
};

{lognor}	{
	PRINT_FUNC("Scanned lognor\n");
	return token::TOKEN_LOGNOR;
};

{logeqv}	{
	PRINT_FUNC("Scanned logeqv\n");
	return token::TOKEN_LOGEQV;
};

{mod}	{
	PRINT_FUNC("Scanned mod\n");
	return token::TOKEN_MOD;
};

{rem}	{
	PRINT_FUNC("Scanned rem\n");
	return token::TOKEN_REM;
};

{incf}	{
	PRINT_FUNC("Scanned incf\n");
	return token::TOKEN_INCF;
};

{decf}	{
	PRINT_FUNC("Scanned decf\n");
	return token::TOKEN_DECF;
};

{defvar}	{
	PRINT_FUNC("Scanned defvar\n");
	return token::TOKEN_DEFVAR;
};

{defun}	{
	PRINT_FUNC("Scanned defun\n");
	return token::TOKEN_DEFUN;
};

{print}	{
	PRINT_FUNC("Scanned print\n");
	return token::TOKEN_PRINT;
};

{loop}	{
	PRINT_FUNC("Scanned loop\n");
	return token::TOKEN_LOOP;
};

{setq}	{
	PRINT_FUNC("Scanned setq\n");
	return token::TOKEN_SETQ;
};

{setf}	{
	PRINT_FUNC("Scanned setf\n");
	return token::TOKEN_SETF;
};

{quote}	{
	PRINT_FUNC("Scanned quote\n");
	return token::TOKEN_QUOTE;
};

{for}	{
	PRINT_FUNC("Scanned for\n");
	return token::TOKEN_FOR;
};

{in}	{
	PRINT_FUNC("Scanned in\n");
	return token::TOKEN_IN;
};

{from}	{
	PRINT_FUNC("Scanned from\n");
	return token::TOKEN_FROM;
};

{to}	{
	PRINT_FUNC("Scanned to\n");
	return token::TOKEN_TO;
};

{dotimes}	{
	PRINT_FUNC("Scanned dotimes\n");
	return token::TOKEN_DOTIMES;
};

{dolist}	{
	PRINT_FUNC("Scanned dolist\n");
	return token::TOKEN_DOLIST;
};

{do}	{
	PRINT_FUNC("Scanned do\n");
	return token::TOKEN_DO;
};

{aref}	{
	PRINT_FUNC("Scanned aref\n");
	return token::TOKEN_AREF;
};

{t}		{
	PRINT_FUNC("Scanned t\n");
	return token::TOKEN_T;
};

{nil}	{
	PRINT_FUNC("Scanned nil\n");
	return token::TOKEN_NIL;
};

{return}	{
	PRINT_FUNC("Scanned return\n");
	return token::TOKEN_RETURN;
};

{returnfrom} {
	PRINT_FUNC("Scanned returnfrom\n");
	return token::TOKEN_RETURN_FROM;
};

{makearray}	{
	PRINT_FUNC("Scanned makearray\n");
	return token::TOKEN_MAKE_ARRAY;
};

{defconstant}	{
	PRINT_FUNC("Scanned defconstant\n");
	return token::TOKEN_DEFCONSTANT;
};

{string}	{
	loc->step();
	PRINT_FUNC("Scanned string: %s\n", yytext);
	yylval->emplace<std::string>(std::string(yytext + 1, yyleng - 2));
	return token::TOKEN_STRING;
}

{comment}	{
	PRINT_FUNC("Scanned comment: %s\n", yytext);
	loc->step();
}

{id}	{
	PRINT_FUNC("Scanned identifier: %s\n", yytext);
	yylval->emplace<std::string>(std::string(yytext, yyleng));
	return token::TOKEN_IDENTIFIER;
};

.		{
	throw DragonLisp::DLParser::syntax_error(*loc, "Invalid character: " + std::string(yytext));
};

<<EOF>>	{
	yyterminate();
};

%%
